# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :funkyabx,
  namespace: FunkyABX,
  ecto_repos: [FunkyABX.Repo]

# Configures the endpoint
config :funkyabx, FunkyABXWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: FunkyABXWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: FunkyABX.PubSub,
  live_view: [signing_salt: "bNwuWfzu"]

{:ok, origin} =
  System.get_env("CORS", ".*")
  |> Regex.compile()

config :cors_plug,
  origin: [origin],
  max_age: 86400,
  methods: ["GET", "POST", "PUT", "OPTIONS"]

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
config :funkyabx, FunkyABX.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
