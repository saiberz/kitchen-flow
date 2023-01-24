defmodule KitchenFlowWeb.StationTicketController do
  use KitchenFlowWeb, :controller
  alias KitchenFlow.Orders

  action_fallback KitchenFlowWeb.FallbackController

  def index(conn, params) do
    tickets = Orders.list_station_tickets(station: params["station"], status: params["status"])
    render(conn, "index.json", tickets: tickets)
  end

  def update_status(conn, %{"id" => id, "status" => status}) do
    ticket = Orders.get_station_ticket!(id)

    with {:ok, updated} <- Orders.transition_ticket(ticket, status) do
      render(conn, "show.json", ticket: updated)
    end
  end
end
