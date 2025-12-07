defmodule Assetronics.Integrations.Adapters.Okta do
  @moduledoc """
  Okta integration adapter for syncing employee/user data.

  This is the main orchestration module that delegates to specialized
  submodules for different aspects of the integration.

  Okta API Documentation: https://developer.okta.com/docs/reference/api/users/

  Authentication: API Token (SSWS) or OAuth 2.0 (recommended)
  Base URL: https://{your-domain}.okta.com/api/v1

  ## Configuration

  To set up Okta integration, provide either:
  - API Token: Set `api_key` with your Okta API token
  - OAuth 2.0: Set `access_token` with OAuth access token (recommended)

  Also configure:
  - `base_url`: Your Okta domain (e.g., https://dev-12345.okta.com)
  - Or `auth_config["domain"]`: Just the domain (e.g., dev-12345.okta.com)
  """

  @behaviour Assetronics.Integrations.Adapter

  alias Assetronics.Integrations.Integration
  alias Assetronics.Integrations.Adapters.Okta.{Api, Client, EmployeeSync}

  require Logger

  @impl true
  def test_connection(%Integration{} = integration) do
    integration
    |> Client.build_client()
    |> Api.test_connection()
  end

  @impl true
  def sync(tenant, %Integration{} = integration) do
    Logger.info("Starting Okta sync for tenant: #{tenant}")

    client = Client.build_client(integration)

    with {:ok, users_data} <- Api.fetch_users(client),
         {:ok, sync_results} <- EmployeeSync.sync_employees(tenant, users_data, integration) do
      Logger.info("Okta sync completed: #{inspect(sync_results)}")
      {:ok, sync_results}
    else
      {:error, reason} ->
        Logger.error("Okta sync failed: #{inspect(reason)}")
        {:error, reason}
    end
  end
end