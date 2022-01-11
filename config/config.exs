# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :funkyabx,
  namespace: FunkyABX,
  ecto_repos: [FunkyABX.Repo],
  analytics: nil,
  env: Mix.env()

# Configures the endpoint
config :funkyabx, FunkyABXWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: FunkyABXWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: FunkyABX.PubSub,
  live_view: [signing_salt: "bNwuWfzu"]

# config :mime, :types, %{
#  "audio/ogg" => ["ogg"]
# }

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
# config :funkyabx, FunkyABX.Mailer, adapter: Swoosh.Adapters.Local

config :funkyabx, FunkyABX.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  ssl: true,
  #       tls: :always,
  #       auth: :always,
  #       dkim: [
  #         s: "default", d: "domain.com",
  #         private_key: {:pem_plain, File.read!("priv/keys/domain.private")}
  #       ],
  retries: 2,
  no_mx_lookups: false

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ex_cldr,
  default_locale: "en",
  default_backend: FunkyABX.Cldr

config :funkyabx, FunkyABX.Cache,
  # When using :shards as backend
  # backend: :shards,
  # GC interval for pushing new generation: 12 hrs
  gc_interval: :timer.hours(12),
  # Max 1 million entries in cache
  max_size: 1_00_000,
  # Max 2 GB of memory
  allocated_memory: 2_000_000_000,
  # GC min timeout: 10 sec
  gc_cleanup_min_timeout: :timer.seconds(10),
  # GC min timeout: 10 min
  gc_cleanup_max_timeout: :timer.minutes(10)

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
