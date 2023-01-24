defmodule KitchenFlowWeb.OrderController do
  use KitchenFlowWeb, :controller
  alias KitchenFlow.Orders

  action_fallback KitchenFlowWeb.FallbackController

  def index(conn, _params) do
    orders = Orders.list_orders()
    render(conn, "index.json", orders: orders)
  end

  def show(conn, %{"id" => id}) do
    order = Orders.get_order!(id)
    render(conn, "show.json", order: order)
  end

  def create(conn, %{"order" => order_params}) do
    with {:ok, order} <- Orders.create_order(order_params) do
      conn
      |> put_status(:created)
      |> render("show.json", order: order)
    end
  end
end
