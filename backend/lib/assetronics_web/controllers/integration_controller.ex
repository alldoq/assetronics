defmodule AssetronicsWeb.IntegrationController do
  use AssetronicsWeb, :controller

  alias Assetronics.Integrations
  alias Assetronics.Integrations.Integration

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  List all integrations for the tenant.

  Query parameters:
  - integration_type: Filter by type (hris, finance, communication, ticketing, monitoring, custom)
  - status: Filter by status (active, inactive, error)
  - provider: Filter by provider (bamboohr, rippling, netsuite, quickbooks, slack, etc.)
  """
  def index(conn, params) do
    tenant = conn.assigns[:tenant]
    opts = build_filters(params)
    integrations = Integrations.list_integrations(tenant, opts)
    render(conn, :index, integrations: integrations)
  end

  @doc """
  Create a new integration.
  """
  def create(conn, %{"integration" => integration_params}) do
    tenant = conn.assigns[:tenant]

    # Transform BambooHR OAuth params to API key params
    transformed_params = transform_bamboohr_params(integration_params)

    with {:ok, %Integration{} = integration} <- Integrations.create_integration(tenant, transformed_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/v1/integrations/#{integration.id}")
      |> render(:show, integration: integration)
    end
  end

  @doc """
  Get a single integration by ID.
  """
  def show(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    integration = Integrations.get_integration!(tenant, id)
    render(conn, :show, integration: integration)
  end

  @doc """
  Update an integration.
  """
  def update(conn, %{"id" => id, "integration" => integration_params}) do
    tenant = conn.assigns[:tenant]
    integration = Integrations.get_integration!(tenant, id)

    # Transform BambooHR OAuth params to API key params
    transformed_params = transform_bamboohr_params(integration_params)

    with {:ok, %Integration{} = integration} <- Integrations.update_integration(tenant, integration, transformed_params) do
      render(conn, :show, integration: integration)
    end
  end

  @doc """
  Delete an integration.
  """
  def delete(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    integration = Integrations.get_integration!(tenant, id)

    with {:ok, %Integration{}} <- Integrations.delete_integration(tenant, integration) do
      send_resp(conn, :no_content, "")
    end
  end

  @doc """
  Trigger a manual sync for an integration.

  Enqueues an Oban background job to perform the sync.
  """
  def trigger_sync(conn, %{"integration_id" => id}) do
    tenant = conn.assigns[:tenant]
    integration = Integrations.get_integration!(tenant, id)

    case Integrations.trigger_sync(tenant, integration) do
      {:ok, _job} ->
        json(conn, %{
          status: "ok",
          message: "Sync triggered successfully",
          integration_id: integration.id
        })

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          status: "error",
          message: "Failed to trigger sync",
          reason: inspect(reason)
        })
    end
  end

  @doc """
  Test connection to an integration.

  Validates credentials and connectivity without performing a full sync.
  """
  def test_connection(conn, %{"integration_id" => id}) do
    tenant = conn.assigns[:tenant]
    integration = Integrations.get_integration!(tenant, id)

    case Integrations.test_connection(tenant, integration) do
      {:ok, result} ->
        json(conn, %{
          status: "ok",
          message: "Connection successful",
          integration_id: integration.id,
          provider: integration.provider,
          result: result
        })

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          status: "error",
          message: "Connection failed",
          integration_id: integration.id,
          provider: integration.provider,
          reason: inspect(reason)
        })
    end
  end

  @doc """
  Enable sync for an integration.
  """
  def enable_sync(conn, %{"integration_id" => id}) do
    tenant = conn.assigns[:tenant]
    integration = Integrations.get_integration!(tenant, id)

    with {:ok, %Integration{} = integration} <- Integrations.enable_sync(tenant, integration) do
      render(conn, :show, integration: integration)
    end
  end

  @doc """
  Disable sync for an integration.
  """
  def disable_sync(conn, %{"integration_id" => id}) do
    tenant = conn.assigns[:tenant]
    integration = Integrations.get_integration!(tenant, id)

    with {:ok, %Integration{} = integration} <- Integrations.disable_sync(tenant, integration) do
      render(conn, :show, integration: integration)
    end
  end

  @doc """
  Get sync logs/history for an integration.
  """
  def sync_history(conn, %{"integration_id" => id} = params) do
    tenant = conn.assigns[:tenant]
    limit = parse_integer(params["limit"], 50)

    sync_logs = Integrations.get_sync_history(tenant, id, limit)

    json(conn, %{
      data: Enum.map(sync_logs, fn log ->
        %{
          id: log.id,
          status: log.status,
          started_at: log.last_sync_at,
          completed_at: log.last_successful_sync_at,
          records_synced: log.sync_metadata["records_synced"],
          error_message: log.last_sync_error
        }
      end)
    })
  end

  # Private helpers

  defp build_filters(params) do
    []
    |> add_filter(:integration_type, params["integration_type"])
    |> add_filter(:status, params["status"])
    |> add_filter(:provider, params["provider"])
  end

  defp add_filter(filters, _key, nil), do: filters
  defp add_filter(filters, key, value), do: [{key, value} | filters]

  defp parse_integer(nil, default), do: default
  defp parse_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> default
    end
  end
  defp parse_integer(value, _default) when is_integer(value), do: value
  defp parse_integer(_, default), do: default

  # Transform BambooHR OAuth-style params to API key authentication
  # This allows the UI to keep OAuth fields but map them to API key auth
  defp transform_bamboohr_params(%{"provider" => "bamboohr", "auth_config" => auth_config} = params)
       when is_map(auth_config) do
    # Extract client_secret from auth_config and use it as the API key
    api_key = auth_config["client_secret"]

    params
    |> Map.put("auth_type", "api_key")
    |> Map.put("api_key", api_key)
    |> Map.delete("auth_config")  # Remove auth_config since we're using api_key
  end

  # For non-BambooHR integrations or when auth_config is not provided, return params unchanged
  defp transform_bamboohr_params(params), do: params
end
