defmodule Assetronics.Workers.ScheduledSyncWorker do
  @moduledoc """
  Scheduled worker that runs periodically to trigger syncs for integrations.

  This worker checks for integrations that need syncing based on their
  sync_frequency and enqueues SyncIntegrationWorker jobs for them.

  Configured to run via Oban cron:
  - Every 15 minutes for frequent checks
  - Respects each integration's sync_frequency setting
  """

  use Oban.Worker,
    queue: :default,
    max_attempts: 1

  alias Assetronics.Accounts
  alias Assetronics.Integrations
  alias Assetronics.Workers.SyncIntegrationWorker

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Logger.info("Running scheduled sync worker")

    # Get all active tenants
    tenants = Accounts.list_active_tenants()

    results = %{
      tenants_checked: length(tenants),
      integrations_found: 0,
      sync_jobs_enqueued: 0,
      errors: 0
    }

    results = Enum.reduce(tenants, results, fn tenant, acc ->
      case process_tenant_integrations(tenant) do
        {:ok, stats} ->
          acc
          |> Map.update!(:integrations_found, &(&1 + stats.integrations_found))
          |> Map.update!(:sync_jobs_enqueued, &(&1 + stats.jobs_enqueued))

        {:error, _reason} ->
          Map.update!(acc, :errors, &(&1 + 1))
      end
    end)

    Logger.info("Scheduled sync worker completed: #{inspect(results)}")
    :ok
  end

  defp process_tenant_integrations(tenant) do
    # Get integrations that need syncing
    integrations = Integrations.list_integrations_needing_sync(tenant.slug)

    stats = %{
      integrations_found: length(integrations),
      jobs_enqueued: 0
    }

    stats = Enum.reduce(integrations, stats, fn integration, acc ->
      case enqueue_sync_job(tenant.slug, integration) do
        {:ok, _job} ->
          Map.update!(acc, :jobs_enqueued, &(&1 + 1))

        {:error, reason} ->
          Logger.error("Failed to enqueue sync for integration #{integration.id}: #{inspect(reason)}")
          acc
      end
    end)

    {:ok, stats}
  rescue
    error ->
      Logger.error("Error processing tenant #{tenant.slug}: #{inspect(error)}")
      {:error, error}
  end

  defp enqueue_sync_job(tenant, integration) do
    %{
      tenant: tenant,
      integration_id: integration.id,
      integration_type: integration.integration_type,
      provider: integration.provider
    }
    |> SyncIntegrationWorker.new(queue: :integrations, schedule_in: schedule_delay(integration))
    |> Oban.insert()
  end

  # Add small random delay to avoid thundering herd
  defp schedule_delay(_integration) do
    :rand.uniform(60)  # 0-60 seconds
  end
end
