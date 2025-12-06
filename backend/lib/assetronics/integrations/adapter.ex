defmodule Assetronics.Integrations.Adapter do
  @moduledoc """
  Behavior for integration adapters.

  Each integration adapter must implement these callbacks to handle
  syncing data from external systems.
  """

  alias Assetronics.Integrations.Integration

  @doc """
  Tests the connection to the external integration.

  Returns {:ok, result} if connection is successful.
  Returns {:error, reason} if connection fails.
  """
  @callback test_connection(Integration.t()) :: {:ok, map()} | {:error, any()}

  @doc """
  Syncs data from the external integration.

  Returns {:ok, result} with sync statistics.
  Returns {:error, reason} if sync fails.
  """
  @callback sync(tenant :: String.t(), Integration.t()) :: {:ok, map()} | {:error, any()}

  @doc """
  Returns the adapter for a given integration type and provider.
  """
  def get_adapter("hris", "bamboohr"), do: Assetronics.Integrations.Adapters.BambooHR
  def get_adapter("hris", "rippling"), do: Assetronics.Integrations.Adapters.Rippling
  def get_adapter("finance", "netsuite"), do: Assetronics.Integrations.Adapters.NetSuite
  def get_adapter("finance", "quickbooks"), do: Assetronics.Integrations.Adapters.QuickBooks
  def get_adapter("communication", "slack"), do: Assetronics.Integrations.Adapters.Slack
  def get_adapter("identity", "okta"), do: Assetronics.Integrations.Adapters.Okta
  def get_adapter("mdm", "intune"), do: Assetronics.Integrations.Adapters.Intune
  def get_adapter("mdm", "jamf"), do: Assetronics.Integrations.Adapters.Jamf
  def get_adapter("mdm", "google_workspace"), do: Assetronics.Integrations.Adapters.GoogleWorkspace
  def get_adapter("email", "gmail"), do: Assetronics.Integrations.Adapters.Gmail
  def get_adapter("email", "microsoft_graph"), do: Assetronics.Integrations.Adapters.MicrosoftGraph
  def get_adapter("procurement", "dell"), do: Assetronics.Integrations.Adapters.Dell
  def get_adapter("procurement", "cdw"), do: Assetronics.Integrations.Adapters.Cdw
  def get_adapter(_type, _provider), do: nil

  @doc """
  Dispatches a sync operation to the appropriate adapter.
  """
  def dispatch_sync(tenant, %Integration{} = integration) do
    case get_adapter(integration.integration_type, integration.provider) do
      nil ->
        {:error, :unsupported_integration}

      adapter ->
        adapter.sync(tenant, integration)
    end
  end

  @doc """
  Dispatches a test connection to the appropriate adapter.
  """
  def dispatch_test(integration) do
    case get_adapter(integration.integration_type, integration.provider) do
      nil ->
        {:error, :unsupported_integration}

      adapter ->
        adapter.test_connection(integration)
    end
  end
end
