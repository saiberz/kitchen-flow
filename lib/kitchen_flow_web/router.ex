defmodule KitchenFlowWeb.Router do
  use KitchenFlowWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", KitchenFlowWeb do
    pipe_through :api
  end
end
