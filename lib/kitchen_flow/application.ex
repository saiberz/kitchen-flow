defmodule KitchenFlow.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      KitchenFlow.Repo,
      # Start the Telemetry supervisor
      KitchenFlowWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: KitchenFlow.PubSub},
      # Start the Endpoint (http/https)
      KitchenFlow.Broker.ConnectionManager,
      {KitchenFlow.Events.OutboxWorker, [poll: Application.get_env(:kitchen_flow, :broker)[:enabled]]},
      KitchenFlow.Broker.StationConsumer,
      KitchenFlowWeb.Endpoint
      # Start a worker by calling: KitchenFlow.Worker.start_link(arg)
      # {KitchenFlow.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KitchenFlow.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    KitchenFlowWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
