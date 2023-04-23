defmodule FunkyABX.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FunkyABX.Cache,
      # Start the Telemetry supervisor
      FunkyABXWeb.Telemetry,
      # Start the Ecto repository
      FunkyABX.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: FunkyABX.PubSub},
      # Start Finch
      {Finch, name: FunkyABX.Finch},
      {Task.Supervisor, name: FunkyABX.TaskSupervisor},
      {Oban, Application.fetch_env!(:funkyabx, Oban)},
      # Start the Endpoint (http/https)
      FunkyABXWeb.Endpoint
      # Start a worker by calling: FunkyABX.Worker.start_link(arg)
      # {FunkyABX.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FunkyABX.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FunkyABXWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
