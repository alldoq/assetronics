defmodule AssetronicsWeb.IntegrationJSON do
  alias Assetronics.Integrations.Integration

  @doc """
  Renders a list of integrations.
  """
  def index(%{integrations: integrations}) do
    %{data: for(integration <- integrations, do: data(integration))}
  end

  @doc """
  Renders a single integration.
  """
  def show(%{integration: integration}) do
    %{data: data(integration)}
  end

  defp data(%Integration{} = integration) do
    %{
      id: integration.id,
      name: integration.name,
      integration_type: integration.integration_type,
      provider: integration.provider,
      status: integration.status,
      auth_type: integration.auth_type,
      base_url: integration.base_url,
      sync_enabled: integration.sync_enabled,
      sync_frequency: integration.sync_frequency,
      last_sync_at: integration.last_sync_at,
      last_sync_status: integration.last_sync_status,
      next_sync_at: integration.next_sync_at,
      last_sync_error: integration.last_sync_error,
      total_syncs: integration.total_syncs,
      failed_syncs: integration.failed_syncs,
      webhook_url: integration.webhook_url,
      token_expires_at: integration.token_expires_at,
      inserted_at: integration.inserted_at,
      updated_at: integration.updated_at
    }
    |> add_credentials_status(integration)
    |> add_safe_auth_config(integration)
    |> add_sync_health(integration)
  end

  # Add credential status without exposing actual credentials
  defp add_credentials_status(data, %Integration{} = integration) do
    credentials_configured = case integration.auth_type do
      "api_key" -> !is_nil(integration.api_key) && byte_size(integration.api_key) > 0
      "oauth2" -> !is_nil(integration.access_token) && byte_size(integration.access_token) > 0
      "basic" -> !is_nil(integration.api_key) && !is_nil(integration.api_secret)
      "custom" -> !is_nil(integration.auth_config) && map_size(integration.auth_config) > 0
      _ -> false
    end

    Map.put(data, :credentials_configured, credentials_configured)
  end

  # Add safe auth_config metadata (only non-sensitive fields)
  defp add_safe_auth_config(data, %Integration{} = integration) do
    safe_config = case integration.auth_config do
      nil -> %{}
      config ->
        # Only expose metadata, never actual credentials
        %{
          # For Google Workspace, expose admin_email but not service_account_json
          "admin_email" => config["admin_email"],
          # For other providers, add other safe metadata as needed
          "endpoint" => config["endpoint"]
        }
        |> Enum.reject(fn {_k, v} -> is_nil(v) end)
        |> Map.new()
    end

    Map.put(data, :auth_config, safe_config)
  end

  # Add sync health status
  defp add_sync_health(data, %Integration{} = integration) do
    health = cond do
      is_nil(integration.last_sync_at) ->
        "never_synced"

      integration.last_sync_status == "failed" ->
        "error"

      integration.sync_enabled && integration.last_sync_status == "success" ->
        time_since_sync = DateTime.diff(DateTime.utc_now(), integration.last_sync_at, :hour)
        cond do
          time_since_sync < 2 -> "healthy"
          time_since_sync < 24 -> "warning"
          true -> "stale"
        end

      !integration.sync_enabled ->
        "disabled"

      true ->
        "unknown"
    end

    Map.put(data, :sync_health, health)
  end
end
