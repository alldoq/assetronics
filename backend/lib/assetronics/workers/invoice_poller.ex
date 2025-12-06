defmodule Assetronics.Workers.InvoicePoller do
  @moduledoc """
  Oban worker to periodically poll active email integrations for new invoices.
  """
  use Oban.Worker, queue: :integrations, unique: [period: 300] # Unique for 5 mins

  alias Assetronics.Integrations
  alias Assetronics.Integrations.Adapter
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"tenant" => tenant} = _args}) do
    # Fetch all active email integrations for this tenant
    # TODO: Modify list_active_integrations to filter by type or do it in Enum
    integrations = Integrations.list_active_integrations(tenant)
    
    email_integrations = Enum.filter(integrations, fn i -> 
      i.integration_type == "email" and i.sync_enabled 
    end)
    
    results = Enum.map(email_integrations, fn integration ->
      process_integration(tenant, integration)
    end)
    
    failures = Enum.filter(results, fn {status, _} -> status == :error end)
    
    if Enum.empty?(failures) do
      :ok
    else
      {:error, "Some email syncs failed: #{inspect(failures)}"}
    end
  end
  
  # Allow running without tenant arg to scan ALL tenants (cron style)
  def perform(%Oban.Job{}) do
    # In a multi-tenant system, we might need to iterate all tenants
    # For now, let's assume this worker is enqueued per-tenant or we fetch all tenants
    # Assetronics.Tenants.list_tenants() |> Enum.each(...)
    :ok 
  end

  defp process_integration(tenant, integration) do
    Logger.info("Polling email for integration: #{integration.name} (#{integration.provider})")
    
    case Adapter.dispatch_sync(tenant, integration) do
      {:ok, stats} ->
        Integrations.record_sync_success(tenant, integration, stats)
        {:ok, stats}
        
      {:error, reason} ->
        Logger.error("Email sync failed for #{integration.name}: #{inspect(reason)}")
        Integrations.record_sync_failure(tenant, integration, inspect(reason))
        {:error, reason}
    end
  end
end
