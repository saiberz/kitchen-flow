defmodule KitchenFlowWeb.Router do
  use KitchenFlowWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug KitchenFlowWeb.Plugs.LocalePlug
  end

  scope "/api", KitchenFlowWeb do
    pipe_through :api

    resources "/menu-items", MenuItemController, only: [:index, :create]
    resources "/orders", OrderController, only: [:index, :show, :create]
    get "/tickets", StationTicketController, :index
    patch "/tickets/:id/status", StationTicketController, :update_status
  end
end
