import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :teal_multiplayer, TealMultiplayer.Repo,
  database: "../priv/db/teal_multiplayer_#{config_env()}.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 1

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :teal_multiplayer, TealMultiplayerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "MmXpPkiiZSwyvUTcjU7qiZKYq9Np0nI5cDban1H5+Bw5zGhx5cIxA6FzNiKyod3d",
  server: false

# In test we don't send emails.
config :teal_multiplayer, TealMultiplayer.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
