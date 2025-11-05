# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :funkyabx, :scopes,
  accounts_user: [
    default: false,
    module: FunkyABX.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: FunkyABX.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :funkyabx, :scopes,
  user: [
    default: true,
    module: FunkyABX.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: FunkyABX.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :funkyabx,
  namespace: FunkyABX,
  ecto_repos: [FunkyABX.Repo],
  generators: [timestamp_type: :utc_datetime],
  analytics: nil,
  env: Mix.env(),
  local_url_folder: "local",
  file_module: FunkyABX.Files.Local

# Configures the endpoint
config :funkyabx, FunkyABXWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: FunkyABXWeb.ErrorHTML, json: FunkyABXWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: FunkyABX.PubSub,
  live_view: [signing_salt: "28vawG63"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :funkyabx, FunkyABX.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
# config :esbuild,
#  version: "0.25.4",
#  funkyabx: [
#    args:
#      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
#    cd: Path.expand("../assets", __DIR__),
#    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
#  ]

# Configure tailwind (the version is required)
# config :tailwind,
#  version: "4.1.7",
#  funkyabx: [
#    args: ~w(
#      --input=assets/css/app.css
#      --output=priv/static/assets/css/app.css
#    ),
#    cd: Path.expand("..", __DIR__)
#  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :funkyabx, FunkyABXWeb.Gettext,
  default_locale: "en",
  locales: ~w(en fr)

config :ex_cldr,
  default_locale: "en",
  default_backend: FunkyABX.Cldr

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :mime, :types, %{
  #  "audio/ogg" => ["ogg"]
  "audio/flac" => ["flac"]
}

config :funkyabx, Oban,
  repo: FunkyABX.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [default: 2, closing: 2, user_delete: 1]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
