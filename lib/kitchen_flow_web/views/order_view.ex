defmodule KitchenFlowWeb.OrderView do
  use KitchenFlowWeb, :view
  alias KitchenFlowWeb.StationTicketView

  def render("index.json", %{orders: orders}) do
    %{data: render_many(orders, __MODULE__, "order.json", as: :order)}
  end

  def render("show.json", %{order: order}) do
    %{data: render_one(order, __MODULE__, "order.json", as: :order)}
  end

  def render("order.json", %{order: order}) do
    %{
      id: order.id,
      table_number: order.table_number,
      status: order.status,
      notes: order.notes,
      inserted_at: order.inserted_at,
      station_tickets:
        render_many(order.station_tickets || [], StationTicketView, "ticket.json", as: :ticket)
    }
  end
end
