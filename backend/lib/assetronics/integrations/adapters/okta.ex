defmodule Assetronics.Integrations.Adapters.Okta do
  @moduledoc """
  Integration adapter for Okta Identity Cloud.

  Supports:
  - User sync (Employees)
  - Application sync (Software Licenses)
  """

  @behaviour Assetronics.Integrations.Adapter

  alias Assetronics.Integrations.Integration
  alias Assetronics.Employees
  alias Assetronics.Software
  require Logger

  @impl true
  def test_connection(%Integration{} = integration) do
    case get_client(integration) |> Req.get(url: "/api/v1/users?limit=1") do
      {:ok, %{status: 200}} ->
        {:ok, %{success: true, message: "Connection successful"}}

      {:ok, %{status: status}} ->
        {:error, "Connection failed with status #{status}"}

      {:error, reason} ->
        {:error, "Connection failed: #{inspect(reason)}"}
    end
  end

  @impl true
  def sync(tenant, %Integration{} = integration) do
    client = get_client(integration)

    with {:ok, users} <- fetch_users(client),
         {:ok, apps} <- fetch_apps(client) do
      
      # Sync Employees
      sync_results = 
        Enum.map(users, fn user ->
          attrs = map_user_to_employee(user)
          Employees.sync_employee_from_hris(tenant, attrs)
        end)

      # Sync Software (Apps)
      app_results = 
        Enum.map(apps, fn app ->
          attrs = map_app_to_license(app, integration.id)
          license = case Software.list_licenses(tenant) |> Enum.find(&(&1.name == attrs.name and &1.vendor == attrs.vendor)) do
            nil -> 
              {:ok, l} = Software.create_license(tenant, attrs)
              l
            l -> 
              {:ok, updated} = Software.update_license(tenant, l, attrs)
              updated
          end
          
          # Sync Assignments for this App
          sync_app_assignments(tenant, client, app["id"], license.id)
          
          {:ok, license}
        end)

      success_count = Enum.count(sync_results, fn {status, _} -> status == :ok end)
      failed_count = Enum.count(sync_results, fn {status, _} -> status == :error end)

      {:ok, %{
        users_synced: success_count, 
        users_failed: failed_count,
        apps_synced: length(app_results)
      }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Private Helpers

  defp get_client(integration) do
    # Decrypt API Key
    # In a real app, we'd use Assetronics.Vault to decrypt.
    # Assuming integration.api_key is available (decrypted by caller or getter).
    # Since the schema defines it as EncryptedString, we need to ensure it's decrypted.
    # The integration context usually handles this, but here we might receive the struct.
    # If it's loaded via Ecto with Cloak, it might be decrypted struct.
    
    api_token = integration.api_key 
    base_url = integration.base_url

    Req.new(base_url: base_url)
    |> Req.Request.put_header("Authorization", "SSWS #{api_token}")
    |> Req.Request.put_header("Accept", "application/json")
    |> Req.Request.put_header("Content-Type", "application/json")
  end

  defp fetch_users(client) do
    # Fetch active users
    case Req.get(client, url: "/api/v1/users?filter=status eq \"ACTIVE\"") do
      {:ok, %{status: 200, body: users}} -> {:ok, users}
      {:ok, %{status: status}} -> {:error, "Failed to fetch users: #{status}"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp fetch_apps(client) do
    # Fetch active apps
    case Req.get(client, url: "/api/v1/apps?filter=status eq \"ACTIVE\"&limit=200") do
      {:ok, %{status: 200, body: apps}} -> {:ok, apps}
      {:ok, %{status: status}} -> {:error, "Failed to fetch apps: #{status}"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp map_user_to_employee(user) do
    profile = user["profile"]
    
    %{ 
      first_name: profile["firstName"],
      last_name: profile["lastName"],
      email: profile["email"],
      job_title: profile["title"],
      department: profile["department"],
      hris_id: profile["employeeNumber"] || user["id"], # Fallback to Okta ID
      employment_status: "active",
      mobile_phone: profile["mobilePhone"],
      start_date: parse_date(user["created"]),
      last_login_at: parse_datetime(user["lastLogin"])
    }
  end

  defp map_app_to_license(app, integration_id) do
    %{ 
      name: app["label"],
      vendor: "Okta App", # Okta doesn't always provide vendor in list
      description: "Imported from Okta",
      status: "active",
      sso_app_id: app["id"],
      integration_id: integration_id,
      # Default fields
      total_seats: 0, # We don't know total seats from Okta usually
      annual_cost: 0,
      cost_per_seat: 0
    }
  end

  defp parse_date(nil), do: nil
  defp parse_date(iso_string) do
    case DateTime.from_iso8601(iso_string) do
      {:ok, dt, _} -> DateTime.to_date(dt)
      _ -> nil
    end
  end

  defp parse_datetime(nil), do: nil
  defp parse_datetime(iso_string) do
    case DateTime.from_iso8601(iso_string) do
      {:ok, dt, _} -> DateTime.to_naive(dt)
      _ -> nil
    end
  end

  defp sync_app_assignments(tenant, client, okta_app_id, license_id) do
    case Req.get(client, url: "/api/v1/apps/#{okta_app_id}/users?limit=200") do
      {:ok, %{status: 200, body: app_users}} ->
        Enum.each(app_users, fn app_user ->
          # Find employee by Okta ID (hris_id)
          case Employees.get_employee_by_hris_id(tenant, app_user["id"]) do
            {:ok, employee} ->
              Software.assign_software(tenant, employee.id, license_id, %{
                assigned_at: parse_date(app_user["created"]),
                last_used_at: parse_datetime(app_user["lastUpdated"]) # Using lastUpdated as proxy for access
              })
            _ -> 
              Logger.warning("Employee not found for Okta App User ID: #{app_user["id"]}")
          end
        end)
      _ -> Logger.error("Failed to fetch users for app #{okta_app_id}")
    end
  end
end
