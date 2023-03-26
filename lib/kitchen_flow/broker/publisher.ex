defmodule KitchenFlow.Broker.Publisher do
  require Logger
  alias KitchenFlow.Broker.ConnectionManager
  alias KitchenFlow.Orders.StationTicket

  def routing_key_for(%StationTicket{station: station}) do
    "ticket.routed.#{station}"
  end

  def build_ticket_event(%StationTicket{} = ticket, event_id \\ Ecto.UUID.generate()) do
    %{
      "event_id" => event_id,
      "event_type" => "ticket.routed",
      "occurred_at" => DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      "ticket_id" => ticket.id,
      "order_id" => ticket.order_id,
      "station" => ticket.station,
      "table_number" => ticket.table_number,
      "status" => ticket.status,
      "target_prep_seconds" => ticket.target_prep_seconds,
      "items" => ticket.items_payload
    }
  end

  def publish(routing_key, payload_map, opts \\ []) when is_map(payload_map) do
    config = Application.get_env(:kitchen_flow, :broker, [])
    exchange = Keyword.get(config, :exchange, "kitchen.events")
    event_id = payload_map["event_id"] || Keyword.get(opts, :event_id) || Ecto.UUID.generate()

    if Keyword.get(config, :enabled, true) do
      case ConnectionManager.get_channel() do
        {:ok, chan} ->
          json = Jason.encode!(payload_map)

          AMQP.Basic.publish(chan, exchange, routing_key, json,
            persistent: true,
            message_id: event_id,
            content_type: "application/json"
          )

        {:error, reason} ->
          {:error, reason}
      end
    else
      :ok
    end
  end
end
