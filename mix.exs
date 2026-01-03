defmodule FunkyABX.MixProject do
  use Mix.Project

  def project do
    [
      app: :funkyabx,
      version: "0.54.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader],
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

  def cli do
    [
      preferred_envs: [precommit: :test]
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
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.8.1"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1.0"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      #      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      #      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      #      {:heroicons,
      #        github: "tailwindlabs/heroicons",
      #        tag: "v2.2.0",
      #        sparse: "optimized",
      #        app: false,
      #        compile: false,
      #        depth: 1},
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.8"},
      {:mail, "~> 0.4"},
      {:mua, "~> 0.2.0"},
      {:oban, "~> 2.19"},
      {:mime, "~> 2.0"},
      {:mogrify, "~> 0.9.3"},
      {:ex_cldr, "~> 2.43"},
      {:ex_cldr_dates_times, "~> 2.24"},
      {:ex_cldr_plugs, "~> 1.3.0"},
      {:remote_ip, "~> 1.0"},
      {:earmark, "~> 1.4.48"},
      {:ecto_autoslug_field, "~> 3.1"},
      {:ex_aws, "~> 2.6"},
      {:ex_aws_s3, "~> 2.5"},
      {:auto_linker, "~> 1.0"},
      {:shortuuid, "~> 4.0"},
      {:tzdata, "~> 1.1"},
      {:httpoison, "~> 2.0"},
      {:pbkdf2_elixir, "~> 2.3"},
      {:floki, ">= 0.30.0"},
      {:phoenix_html_helpers, ">= 1.0.0"},
      {:sweet_xml, "~> 0.7.5"}
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
      "assets.setup": ["esbuild.install --if-missing"],
      "assets.build": ["compile", "esbuild funkyabx"],
      "assets.deploy": [
        "cmd --cd assets node build.js --deploy",
        "phx.digest"
      ],
      precommit: ["compile --warning-as-errors", "deps.unlock --unused", "format", "test"]
    ]
  end
end
