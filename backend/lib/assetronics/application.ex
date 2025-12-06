defmodule Assetronics.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AssetronicsWeb.Telemetry,
      # Start Vault before Repo (Repo may need encryption)
      Assetronics.Vault,
      # Start Repo with rest_for_one strategy consideration
      Assetronics.Repo,
      {DNSCluster, query: Application.get_env(:assetronics, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Assetronics.PubSub},
      # Start Registry for event listeners
      {Registry, keys: :unique, name: Assetronics.ListenerRegistry},
      # Start DynamicSupervisor for event listeners
      {DynamicSupervisor, name: Assetronics.ListenerSupervisor, strategy: :one_for_one},
      # Initialize event listeners for all tenants
      Assetronics.Listeners.Initializer,
      # Start dashboard cache
      Assetronics.Dashboard.Cache,
      # Start Oban after Repo is ready
      {Oban, Application.fetch_env!(:assetronics, Oban)},
      # Start Endpoint last
      AssetronicsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Assetronics.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AssetronicsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
