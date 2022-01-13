defmodule FunkyABX.MixProject do
  use Mix.Project

  def project do
    [
      app: :funkyabx,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:gettext] ++ Mix.compilers(),
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
      {:pbkdf2_elixir, "~> 1.0"},
      {:phoenix, "~> 1.6.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.17.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.5"},
      #      {:esbuild, "~> 0.2", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.5"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:ecto_autoslug_field, "~> 3.0"},
      {:earmark, "1.4.20"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:auto_linker, "~> 1.0"},
      {:hackney, "~> 1.18"},
      {:sweet_xml, "~> 0.7.1"},
      {:gen_smtp, "~> 1.1"},
      {:ex_cldr_dates_times, "~> 2.0"},
      {:httpoison, "~> 1.8"},
      {:remote_ip, "~> 1.0"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:mock, "~> 0.3.0", only: :test},
      {:statistics, "~> 0.6.2"},
      {:nebulex, "~> 2.3"},
      {:decorator, "~> 1.4"},
      {:mime, "~> 2.0"}
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
      setup: ["deps.get", "ecto.setup", "cmd --cd assets npm install"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["cmd --cd assets node build.js --deploy", "phx.digest"]
    ]
  end
end
