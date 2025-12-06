defmodule Assetronics.Workers.SyncIntegrationWorker do
  @moduledoc """
  Background worker for syncing data from external integrations.

  Handles:
  - HRIS syncs (BambooHR, Rippling, etc.)
  - Finance syncs (NetSuite, QuickBooks, etc.)
  - ITSM syncs (ServiceNow, Jira, etc.)

  Uses Oban for job processing with retry logic.
  """

  use Oban.Worker,
    queue: :integrations,
    max_attempts: 3,
    priority: 1

  alias Assetronics.Integrations
  alias Assetronics.Integrations.Adapter
  alias Assetronics.Accounts
  alias Assetronics.Notifications

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "tenant" => tenant,
          "integration_id" => integration_id,
          "integration_type" => _integration_type,
          "provider" => _provider
        }
      }) do
    start_time = System.monotonic_time()
    integration = Integrations.get_integration!(tenant, integration_id)
    provider = integration.provider

    Logger.info("Starting sync for integration #{integration.id} (#{integration.provider})")

    result = case Adapter.dispatch_sync(tenant, integration) do
      {:ok, sync_result} ->
        Logger.info("Sync completed successfully: #{inspect(sync_result)}")
        Integrations.record_sync_success(tenant, integration, sync_result)

        # Emit telemetry for success
        duration = System.monotonic_time() - start_time
        records_synced = Map.get(sync_result, :records_synced, 0)

        :telemetry.execute(
          [:assetronics, :integrations, :sync, :stop],
          %{duration: duration},
          %{tenant: tenant, provider: provider, status: :success}
        )
        :telemetry.execute(
          [:assetronics, :integrations, :sync, :success],
          %{count: 1},
          %{tenant: tenant, provider: provider}
        )
        :telemetry.execute(
          [:assetronics, :integrations, :sync, :records],
          %{count: records_synced},
          %{tenant: tenant, provider: provider}
        )

        :ok

      {:error, reason} ->
        error_message = inspect(reason)
        Logger.error("Sync failed: #{error_message}")
        Integrations.record_sync_failure(tenant, integration, error_message)

        # Emit telemetry for failure
        duration = System.monotonic_time() - start_time
        :telemetry.execute(
          [:assetronics, :integrations, :sync, :stop],
          %{duration: duration},
          %{tenant: tenant, provider: provider, status: :failure}
        )
        :telemetry.execute(
          [:assetronics, :integrations, :sync, :failure],
          %{count: 1},
          %{tenant: tenant, provider: provider}
        )

        # Notify admins of integration sync failure
        notify_admins_of_sync_failure(tenant, integration, error_message)

        {:error, reason}
    end

    result
  end

  # Notify admin and super_admin users when integration sync fails
  defp notify_admins_of_sync_failure(tenant, integration, error_message) do
    # Get all admin users
    admin_users = Accounts.list_users_by_role(tenant, "admin")
    super_admin_users = Accounts.list_users_by_role(tenant, "super_admin")

    all_admins = admin_users ++ super_admin_users

    Enum.each(all_admins, fn admin ->
      Notifications.notify(
        tenant,
        admin.id,
        "integration_sync_failed",
        %{
          title: "Integration sync failed",
          body: "#{integration.provider} sync failed: #{String.slice(error_message, 0, 100)}",
          integration_id: integration.id,
          integration_name: integration.name,
          provider: integration.provider,
          error: error_message
        }
      )
    end)

    Logger.info("Sent integration sync failure notifications to #{length(all_admins)} admins")
  end
end
