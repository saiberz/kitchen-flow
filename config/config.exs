# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :kitchen_flow,
  ecto_repos: [KitchenFlow.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :kitchen_flow, KitchenFlowWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: KitchenFlowWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: KitchenFlow.PubSub,
  live_view: [signing_salt: "3QvDD+aA"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
config :kitchen_flow, :broker,
  url: "amqp://guest:guest@localhost:5672",
  exchange: "kitchen.events",
  dlx_exchange: "kitchen.dlx",
  dlq_queue: "kitchen.dlq",
  enabled: true

import_config "#{config_env()}.exs"
