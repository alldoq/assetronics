defmodule Assetronics.Integrations.Adapters.BambooHR do
  @moduledoc """
  BambooHR integration adapter for syncing employee data.

  This is the main orchestration module that delegates to specialized
  submodules for different aspects of the integration.

  BambooHR API Documentation: https://documentation.bamboohr.com/docs

  Authentication: API Key (Basic Auth with x-api-key header) or OAuth
  Base URL: https://api.bamboohr.com/api/gateway.php/{subdomain}/v1/
  """

  @behaviour Assetronics.Integrations.Adapter

  alias Assetronics.Integrations.Integration
  alias Assetronics.Integrations.Adapters.BambooHR.{Api, Client, EmployeeSync}

  require Logger

  @impl true
  def test_connection(%Integration{} = integration) do
    integration
    |> Client.build_client()
    |> Api.test_connection()
  end

  @impl true
  def sync(tenant, %Integration{} = integration) do
    Logger.info("Starting BambooHR sync for tenant: #{tenant}")

    client = Client.build_client(integration)

    with {:ok, employees_data} <- Api.fetch_employees(client),
         {:ok, sync_results} <- EmployeeSync.sync_employees(tenant, employees_data, integration) do
      Logger.info("BambooHR sync completed: #{inspect(sync_results)}")
      {:ok, sync_results}
    else
      {:error, reason} ->
        Logger.error("BambooHR sync failed: #{inspect(reason)}")
        {:error, reason}
    end
  end
end