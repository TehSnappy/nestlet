defmodule Nestlet.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      NestletWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:nestlet, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Nestlet.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Nestlet.Finch},
      # Start a worker by calling: Nestlet.Worker.start_link(arg)
      # {Nestlet.Worker, arg},
      # Start to serve requests, typically the last entry
      NestletWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nestlet.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NestletWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
