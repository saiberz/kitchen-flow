import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :kitchen_flow, KitchenFlow.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "kitchen_flow_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :kitchen_flow, KitchenFlowWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "7QUz5Jy/EYZhphc7HJ5LIjLEIOXZOfzdqz0F9oSDJaenScQoNSY52+YhM+4OF91p",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :kitchen_flow, :broker, enabled: false
