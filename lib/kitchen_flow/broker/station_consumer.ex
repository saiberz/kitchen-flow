defmodule KitchenFlow.Broker.StationConsumer do
  use GenServer
  require Logger
  alias KitchenFlow.Broker.ConnectionManager

  @stations ~w(grill cold bar pastry)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def process_payload(raw_json) when is_binary(raw_json) do
    case Jason.decode(raw_json) do
      {:ok, %{"event_id" => event_id, "ticket_id" => ticket_id, "station" => station} = event}
      when is_binary(event_id) and is_binary(ticket_id) and is_binary(station) ->
        broadcast_ticket(event)
        {:ok, event}

      {:ok, _invalid} ->
        {:error, :missing_required_fields}

      {:error, _} ->
        {:error, :invalid_json}
    end
  end

  @impl true
  def init(opts) do
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
      {:ok, _event} ->
        AMQP.Basic.ack(chan, tag)

      {:error, reason} ->
        Logger.warn("Rejecting malformed station event to DLQ (#{inspect(reason)})")
        AMQP.Basic.reject(chan, tag, requeue: false)
    end

    {:noreply, state}
  end
end
