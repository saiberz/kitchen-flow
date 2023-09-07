defmodule KitchenFlowWeb.StationTicketView do
  use KitchenFlowWeb, :view

  def render("index.json", %{tickets: tickets}) do
    %{data: render_many(tickets, __MODULE__, "ticket.json", as: :ticket)}
  end

  def render("show.json", %{ticket: ticket}) do
    %{data: render_one(ticket, __MODULE__, "ticket.json", as: :ticket)}
  end

  def render("ticket.json", %{ticket: ticket}) do
    %{
      id: ticket.id,
      order_id: ticket.order_id,
      station: ticket.station,
      status: ticket.status,
      status_label: Gettext.dgettext(KitchenFlowWeb.Gettext, "kitchen", ticket.status),
      table_number: ticket.table_number,
      items: ticket.items_payload,
      target_prep_seconds: ticket.target_prep_seconds,
      started_at: ticket.started_at,
      ready_at: ticket.ready_at,
      served_at: ticket.served_at,
      inserted_at: ticket.inserted_at
    }
  end
end
