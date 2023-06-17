defmodule KitchenFlow.Events.OutboxWorker do
  use GenServer
  import Ecto.Query, warn: false
  require Logger

  alias KitchenFlow.Broker.Publisher
  alias KitchenFlow.Events.OutboxEvent
  alias KitchenFlow.Repo

  @poll_interval_ms 2_000
  @max_attempts 5

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def flush_pending(batch_size \\ 25) do
    pending =
      OutboxEvent
      |> where([e], e.status == "pending" and e.attempts < ^@max_attempts)
      |> order_by([e], asc: e.inserted_at)
      |> limit(^batch_size)
      |> Repo.all()

    results = Enum.map(pending, &dispatch_event/1)
    {:ok, length(results)}
  end

  def pending_count do
    OutboxEvent
    |> where([e], e.status == "pending")
    |> Repo.aggregate(:count, :id)
  end

  @impl true
  def init(opts) do
    if Keyword.get(opts, :poll, true) do
      schedule_poll()
    end

    {:ok, %{}}
  end

  @impl true
  def handle_info(:poll, state) do
    try do
      flush_pending()
    rescue
      err ->
        Logger.warn("Outbox flush failed cleanly: #{Exception.message(err)}")
    end

    schedule_poll()
    {:noreply, state}
  end

  defp dispatch_event(%OutboxEvent{} = event) do
    case Publisher.publish(event.routing_key, event.payload, event_id: event.id) do
      :ok ->
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        event
        |> OutboxEvent.changeset(%{status: "published", published_at: now})
        |> Repo.update()

      {:error, reason} ->
        attempts = event.attempts + 1
        next_status = if attempts >= @max_attempts, do: "failed", else: "pending"

        event
        |> OutboxEvent.changeset(%{
          attempts: attempts,
          status: next_status,
          last_error: inspect(reason)
        })
        |> Repo.update()
    end
  end

  defp schedule_poll do
    Process.send_after(self(), :poll, @poll_interval_ms)
  end
end
