defmodule KitchenFlowWeb.StationChannel do
  use KitchenFlowWeb, :channel
  alias KitchenFlow.Orders
  alias KitchenFlow.Orders.StationTicket
  alias KitchenFlowWeb.StationTicketView

  @allowed_topics ~w(all grill cold bar pastry)

  @impl true
  def join("station:" <> station, _payload, socket) when station in @allowed_topics do
    filter_station = if station == "all", do: nil, else: station
    tickets = Orders.list_station_tickets(station: filter_station)
    rendered = StationTicketView.render("index.json", %{tickets: tickets})
    {:ok, rendered, assign(socket, :station, station)}
  end

  def join("station:" <> _invalid, _payload, _socket) do
    {:error, %{reason: "unknown_station"}}
  end

  def broadcast_ticket_event(event_name, %StationTicket{} = ticket) do
    payload = StationTicketView.render("ticket.json", %{ticket: ticket})
    KitchenFlowWeb.Endpoint.broadcast("station:#{ticket.station}", event_name, payload)
    KitchenFlowWeb.Endpoint.broadcast("station:all", event_name, payload)
  end

  def broadcast_ticket_event(event_name, %{"station" => station} = payload) do
    KitchenFlowWeb.Endpoint.broadcast("station:#{station}", event_name, payload)
    KitchenFlowWeb.Endpoint.broadcast("station:all", event_name, payload)
  end

  def broadcast_ticket_event(event_name, %{station: station} = payload) do
    KitchenFlowWeb.Endpoint.broadcast("station:#{station}", event_name, payload)
    KitchenFlowWeb.Endpoint.broadcast("station:all", event_name, payload)
  end
end
