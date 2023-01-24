defmodule KitchenFlowWeb.MenuItemController do
  use KitchenFlowWeb, :controller
  alias KitchenFlow.Catalog

  action_fallback KitchenFlowWeb.FallbackController

  def index(conn, params) do
    items = Catalog.list_menu_items(station: params["station"])
    render(conn, "index.json", menu_items: items)
  end

  def create(conn, %{"menu_item" => item_params}) do
    with {:ok, item} <- Catalog.create_menu_item(item_params) do
      conn
      |> put_status(:created)
      |> render("show.json", menu_item: item)
    end
  end
end
