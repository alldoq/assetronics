# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :assetronics,
  ecto_repos: [Assetronics.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configures the endpoint
config :assetronics, AssetronicsWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: AssetronicsWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Assetronics.PubSub,
  live_view: [signing_salt: "XCoZ+266"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :assetronics, Assetronics.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Oban for background jobs
config :assetronics, Oban,
  repo: Assetronics.Repo,
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},  # Keep jobs for 7 days
    {Oban.Plugins.Cron, crontab: [
      # Poll emails every 15 minutes
      {"*/15 * * * *", Assetronics.Workers.InvoicePoller},
      # Example: Clean up old transactions daily at 2am
      # {"0 2 * * *", Assetronics.Workers.CleanupWorker}
    ]}
  ],
  queues: [
    default: 10,
    integrations: 20,  # Higher concurrency for integration workers
    notifications: 5,
    reports: 3
  ]

# Configure Cloak for encryption
# Note: The actual cipher configuration happens in Assetronics.Vault.init/1
# which loads CLOAK_KEY from environment at runtime
config :assetronics, Assetronics.Vault, ciphers: []

# Configure Triplex for multi-tenancy
config :triplex,
  repo: Assetronics.Repo,
  prefix: "tenant_",
  # Reserved tenant names (cannot be used as tenant slugs)
  reserved_tenants: ["public", "www", "admin", "api", "app", "dashboard"],
  # Migrations path for tenant-specific tables (relative to repo's priv directory)
  migrations_path: "tenant_migrations"

# Configure Guardian for JWT authentication
config :assetronics, Assetronics.Guardian,
  issuer: "assetronics",
  secret_key: {Assetronics.Guardian, :fetch_secret_key, []},
  verify_issuer: true,
  ttl: {1, :hour},
  verify_module: Guardian.JWT

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
