defmodule Assetronics.Listeners.Initializer do
  @moduledoc """
  Initializes event listeners for all tenants on application startup.

  This module starts as a supervised task that runs once during application
  boot to ensure all active tenants have their event listeners running.
  """

  use Task, restart: :transient
  require Logger

  alias Assetronics.Accounts
  alias Assetronics.Listeners

  def start_link(_arg) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run do
    # Wait a moment for the application to fully start
    Process.sleep(1000)

    Logger.info("[Listeners.Initializer] Starting event listeners for all tenants")

    tenants = Accounts.list_tenants(status: "active")

    started_count =
      tenants
      |> Enum.map(fn tenant ->
        case Listeners.start_listeners_for_tenant(tenant.slug) do
          {:ok, _pids} ->
            Logger.info("[Listeners.Initializer] Started listeners for tenant: #{tenant.slug}")
            1
          {:error, reason} ->
            Logger.error("[Listeners.Initializer] Failed to start listeners for tenant #{tenant.slug}: #{inspect(reason)}")
            0
        end
      end)
      |> Enum.sum()

    Logger.info("[Listeners.Initializer] Started listeners for #{started_count}/#{length(tenants)} tenants")
  end
end
