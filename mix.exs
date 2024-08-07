defmodule FunkyABX.MixProject do
  use Mix.Project

  def project do
    [
      app: :funkyabx,
      version: "0.4.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers() ++ [:phoenix_swagger],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        prod: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent]
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {FunkyABX.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.1"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.0"},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      #      {:esbuild, "~> 0.5", runtime: Mix.env() == :dev},
      #      {:tailwind, "~> 0.1.8", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.4"},
      {:finch, "~> 0.18"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:ecto_autoslug_field, "~> 3.0"},
      {:earmark, "~> 1.4.0"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:auto_linker, "~> 1.0"},
      {:hackney, "~> 1.20"},
      {:sweet_xml, "~> 0.7.1"},
      {:gen_smtp, "~> 1.2"},
      {:ex_cldr, "~> 2.33"},
      {:ex_cldr_dates_times, "~> 2.0"},
      {:ex_cldr_plugs, "~> 1.2.0"},
      {:httpoison, "~> 1.8"},
      {:remote_ip, "~> 1.0"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:mock, "~> 0.3.0", only: :test},
      # {:statistics, "~> 0.6.2"},
      {:nebulex, "~> 2.4"},
      {:decorator, "~> 1.4"},
      {:mime, "~> 2.0"},
      {:phoenix_swagger, "~> 0.8"},
      {:ex_json_schema, "~> 0.5"},
      {:mogrify, "~> 0.9.2"},
      {:shortuuid, "~> 2.1"},
      {:ex_machina, "~> 2.7.0", only: [:test]},
      {:oban, "~> 2.13"},
      {:tzdata, "~> 1.1"},
      {:pbkdf2_elixir, "~> 2.0"},
      {:floki, "~> 0.36.0"},
      {:bandit, "~> 1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["cmd --cd assets node build.js --deploy", "phx.digest"]
    ]
  end
end
