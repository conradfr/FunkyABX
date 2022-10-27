import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.
if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :funkyabx,
    file_module: FunkyABX.Files.Cloud,
    cdn_prefix: System.get_env("CDN_PREFIX"),
    disqus_id: System.get_env("DISQUS_ID") || nil,
    email_from: System.get_env("EMAIL_FROM"),
    email_to: System.get_env("EMAIL_TO"),
    analytics: System.get_env("ANALYTICS") || nil,
    bucket: System.get_env("S3_BUCKET") || "",
    flac_folder: System.get_env("FLAC_FOLDER"),
    temp_folder: System.get_env("TEMP_FOLDER"),
    img_results_path: System.get_env("IMG_RESULTS") || nil

  config :funkyabx, FunkyABX.Repo,
    # ssl: true,
    # socket_options: [:inet6],
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :funkyabx, FunkyABXWeb.Endpoint,
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    check_origin: [System.get_env("ORIGIN")],
    secret_key_base: secret_key_base,
    url: [host: System.get_env("HOST"), port: 443, scheme: "https"]

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint:
  #
  config :funkyabx, FunkyABXWeb.Endpoint, server: true
  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :funkyabx, FunkyABX.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

  config :funkyabx, FunkyABX.Mailer,
    relay: System.get_env("MAILER_SMTP"),
    username: System.get_env("MAILER_USERNAME"),
    password: System.get_env("MAILER_PASSWORD"),
    port: System.get_env("MAILER_PORT")

  config :ex_aws,
    access_key_id: System.get_env("S3_ACCESS_KEY"),
    secret_access_key: System.get_env("S3_SECRET_KEY")

  config :ex_aws, :s3,
    region: System.get_env("S3_REGION"),
    scheme: "https://",
    host: System.get_env("S3_HOST")
end
