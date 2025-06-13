defmodule TealMultiplayer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TealMultiplayerWeb.Telemetry,
      TealMultiplayer.Repo,
      {DNSCluster, query: Application.get_env(:teal_multiplayer, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TealMultiplayer.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: TealMultiplayer.Finch},
      # Start a worker by calling: TealMultiplayer.Worker.start_link(arg)
      # {TealMultiplayer.Worker, arg},
      # Start to serve requests, typically the last entry
      TealMultiplayerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TealMultiplayer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TealMultiplayerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
