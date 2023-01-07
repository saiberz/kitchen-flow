defmodule KitchenFlow.Repo do
  use Ecto.Repo,
    otp_app: :kitchen_flow,
    adapter: Ecto.Adapters.Postgres
end
