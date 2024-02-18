defmodule KitchenFlow.Broker.StationConsumer do
  use GenServer
  require Logger
  alias KitchenFlow.Broker.ConnectionManager

  @dedup_table :kitchen_flow_seen_events
  @stations ~w(grill cold bar pastry)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def ensure_dedup_table do
    case :ets.whereis(@dedup_table) do
      :undefined ->
        :ets.new(@dedup_table, [:named_table, :set, :public, read_concurrency: true])

      tid ->
        tid
    end
  end

  def process_payload(raw_json) when is_binary(raw_json) do
    ensure_dedup_table()

    case Jason.decode(raw_json) do
      {:ok, %{"event_id" => event_id, "ticket_id" => ticket_id, "station" => station} = event}
      when is_binary(event_id) and is_binary(ticket_id) and is_binary(station) ->
        if :ets.insert_new(@dedup_table, {event_id, System.system_time(:second)}) do
          broadcast_ticket(event)
          {:ok, :processed, event}
        else
          {:ok, :duplicate, event}
        end

      {:ok, _invalid} ->
        {:error, :missing_required_fields}

      {:error, _} ->
        {:error, :invalid_json}
    end
  end

  defp broadcast_ticket(%{"event_type" => type, "ticket" => ticket}) do
    KitchenFlowWeb.StationChannel.broadcast_ticket_event(type, ticket)
  end

  defp broadcast_ticket(%{"ticket_id" => _} = event) do
    type = Map.get(event, "event_type", "ticket_created")
    KitchenFlowWeb.StationChannel.broadcast_ticket_event(type, event)
  end

  defp broadcast_ticket(_), do: :ok

  @impl true
  def init(opts) do
    ensure_dedup_table()
    config = Application.get_env(:kitchen_flow, :broker, [])

    if Keyword.get(opts, :enabled, Keyword.get(config, :enabled, true)) do
      Process.send_after(self(), :subscribe, 500)
    end

    {:ok, %{chan: nil, opts: opts}}
  end

  @impl true
  def handle_info(:subscribe, state) do
    case ConnectionManager.get_channel() do
      {:ok, chan} ->
        Enum.each(@stations, fn station ->
          {:ok, _tag} = AMQP.Basic.consume(chan, "kitchen.station.#{station}")
        end)

        {:noreply, %{state | chan: chan}}

      {:error, _} ->
        Process.send_after(self(), :subscribe, 2_000)
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:basic_consume_ok, _meta}, state), do: {:noreply, state}
  def handle_info({:basic_cancel, _meta}, state), do: {:noreply, state}
  def handle_info({:basic_cancel_ok, _meta}, state), do: {:noreply, state}

  @impl true
  def handle_info({:basic_deliver, payload, %{delivery_tag: tag}}, %{chan: chan} = state) do
    case process_payload(payload) do
      {:ok, _state, _event} ->
        AMQP.Basic.ack(chan, tag)

      {:error, reason} ->
        Logger.warning("Rejecting malformed station event to DLQ (#{inspect(reason)})")
        AMQP.Basic.reject(chan, tag, requeue: false)
    end

    {:noreply, state}
  end
end
