defmodule AssetronicsWeb.AgentController do
  use AssetronicsWeb, :controller
  alias Assetronics.Assets

  action_fallback AssetronicsWeb.FallbackController

  def checkin(conn, params) do
    # Tenant ID resolution
    tenant = conn.assigns[:tenant] || get_req_header(conn, "x-tenant-id") |> List.first()

    if is_nil(tenant) do
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Missing X-Tenant-ID header"})
    else
      case Assets.register_agent_checkin(tenant, params) do
        {:ok, asset} ->
          conn
          |> put_status(:ok)
          |> render(:show, asset: asset)

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(AssetronicsWeb.ChangesetJSON, "error.json", changeset: changeset)
      end
    end
  end

  def scan(conn, params) do
    tenant = conn.assigns[:tenant] || get_req_header(conn, "x-tenant-id") |> List.first()

    if is_nil(tenant) do
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Missing X-Tenant-ID header"})
    else
      case Assets.process_network_scan(tenant, params) do
        {:ok, count} ->
          json(conn, %{success: true, devices_processed: count})

        {:error, reason} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: "Failed to process scan results: #{inspect(reason)}"})
      end
    end
  end
end
