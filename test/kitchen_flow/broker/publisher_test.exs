defmodule KitchenFlow.Broker.PublisherTest do
  use ExUnit.Case, async: true

  alias KitchenFlow.Broker.Publisher
  alias KitchenFlow.Orders.StationTicket

  test "routing_key_for/1 builds topic key for station" do
    ticket = %StationTicket{id: Ecto.UUID.generate(), station: "grill", table_number: 5}
    assert Publisher.routing_key_for(ticket) == "ticket.routed.grill"
  end

  test "build_ticket_event/2 serializes expected event envelope" do
    ticket = %StationTicket{
      id: "e58c8a28-7a00-4a8e-9a8d-111111111111",
      order_id: "a12b3c4d-7a00-4a8e-9a8d-222222222222",
      station: "bar",
      status: "queued",
      table_number: 9,
      target_prep_seconds: 120,
      items_payload: [%{"name" => "Negroni", "quantity" => 2}]
    }

    event = Publisher.build_ticket_event(ticket, "evt-123")
    assert event["event_id"] == "evt-123"
    assert event["event_type"] == "ticket.routed"
    assert event["station"] == "bar"
    assert event["table_number"] == 9
    assert length(event["items"]) == 1
  end
end
