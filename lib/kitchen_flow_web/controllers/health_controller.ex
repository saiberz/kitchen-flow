defmodule KitchenFlowWeb.HealthController do
  use KitchenFlowWeb, :controller
  alias KitchenFlow.Broker.ConnectionManager
  alias KitchenFlow.Events.OutboxWorker
  alias KitchenFlow.Repo

  def live(conn, _params) do
    json(conn, %{status: "ok"})
  end

  def ready(conn, _params) do
    db_ok = check_database()
    broker_ok = check_broker()

    status_code = if db_ok and broker_ok, do: 200, else: 503

    conn
    |> put_status(status_code)
    |> json(%{
      status: if(status_code == 200, do: "ready", else: "degraded"),
      checks: %{
        database: if(db_ok, do: "up", else: "down"),
        rabbitmq: if(broker_ok, do: "up", else: "down")
      }
    })
  end

  def metrics(conn, _params) do
    pending = OutboxWorker.pending_count()
    memory_bytes = :erlang.memory(:total)

    body = """
    # HELP kitchen_flow_outbox_pending_count Number of unpublished outbox events
    # TYPE kitchen_flow_outbox_pending_count gauge
    kitchen_flow_outbox_pending_count #{pending}
    # HELP vm_memory_bytes Total BEAM VM allocated memory in bytes
    # TYPE vm_memory_bytes gauge
    vm_memory_bytes #{memory_bytes}
    """

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, body)
  end

  defp check_database do
    case Ecto.Adapters.SQL.query(Repo, "SELECT 1", []) do
      {:ok, _} -> true
      _ -> false
    end
  end

  defp check_broker do
    config = Application.get_env(:kitchen_flow, :broker, [])

    if Keyword.get(config, :enabled, true) do
      match?({:ok, _chan}, ConnectionManager.get_channel())
    else
      true
    end
  end
end
