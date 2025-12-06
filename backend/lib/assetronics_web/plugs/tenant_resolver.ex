defmodule AssetronicsWeb.Plugs.TenantResolver do
  @moduledoc """
  Plug to resolve the tenant from the request.

  Attempts to extract tenant from (in order):
  1. X-Tenant-ID header
  2. Subdomain (e.g., acme.assetronics.com -> "acme")
  3. JWT token claims (when authentication is implemented)

  Sets conn.assigns[:tenant] with the tenant slug.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def init(opts), do: opts

  def call(conn, _opts) do
    case extract_tenant(conn) do
      {:ok, tenant} ->
        assign(conn, :tenant, tenant)

      {:error, :tenant_not_found} ->
        conn
        |> put_status(:bad_request)
        |> json(%{errors: %{detail: "Tenant not found. Provide X-Tenant-ID header."}})
        |> halt()
    end
  end

  defp extract_tenant(conn) do
    # Try to get tenant from header first
    case get_req_header(conn, "x-tenant-id") do
      [tenant | _] when byte_size(tenant) > 0 ->
        {:ok, tenant}

      _ ->
        # Try to extract from subdomain
        extract_from_subdomain(conn)
    end
  end

  defp extract_from_subdomain(conn) do
    host = conn.host

    case String.split(host, ".") do
      # acme.assetronics.com -> "acme"
      [subdomain, _domain, _tld] when subdomain != "www" and subdomain != "api" ->
        {:ok, subdomain}

      # acme.localhost -> "acme" (for local development)
      [subdomain, "localhost"] when subdomain != "www" and subdomain != "api" ->
        {:ok, subdomain}

      _ ->
        {:error, :tenant_not_found}
    end
  end
end
