defmodule Assetronics.Integrations.Adapters.Intune do

  @behaviour Assetronics.Integrations.Adapter

  alias Assetronics.Integrations.Integration
  alias Assetronics.Assets
  alias Assetronics.Employees
  require Logger

  @impl true
  def test_connection(%Integration{} = integration) do
    case get_client(integration) |> Req.get(url: "/v1.0/deviceManagement/managedDevices?$top=1") do
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
    case Req.get(client, url: "/v1.0/deviceManagement/managedDevices?$top=999") do
      {:ok, %{status: 200, body: %{"value" => devices}}} ->
        if length(devices) > 0 do
          Logger.info("Sample Intune device data: #{inspect(List.first(devices), pretty: true)}")
        end
        results = Enum.map(devices, fn device ->  process_device(tenant, device) end)
        success_count = Enum.count(results, fn {status, _} -> status == :ok end)
        failed_count = Enum.count(results, fn {status, _} -> status == :error end)

        {:ok, %{  devices_synced: success_count,  devices_failed: failed_count }}
      {:error, reason} ->  {:error, reason}
    end
  end

  defp get_client(integration) do
    token = integration.access_token
    Req.new(base_url: "https://graph.microsoft.com")
    |> Req.Request.put_header("Authorization", "Bearer #{token}")
    |> Req.Request.put_header("Accept", "application/json")
  end

  defp process_device(tenant, device) do
    attrs = map_device_to_asset(device)
    user_email = device["userPrincipalName"]
    user_display_name = device["userDisplayName"]

    employee_id =
      if user_email && String.contains?(user_email, "@") do
        case Employees.get_employee_by_email(tenant, user_email) do
          {:ok, emp} -> emp.id
          _ ->
            {first_name, last_name} = parse_name(user_display_name)

            employee_attrs = %{
              email: user_email,
              first_name: first_name,
              last_name: last_name,
              status: "active",
              custom_fields: %{
                "source" => "intune",
                "azure_ad_user_id" => device["userId"]
              }
            }

            case Employees.create_employee(tenant, employee_attrs) do
              {:ok, new_emp} ->
                Logger.info("Created employee #{new_emp.id} for #{user_email}")
                new_emp.id

              {:error, changeset} ->
                Logger.error("Failed to create employee: #{inspect(changeset)}")
                nil
            end
        end
      else
        nil
      end

    attrs = if employee_id, do: Map.put(attrs, :employee_id, employee_id), else: attrs
    attrs = if employee_id, do: Map.put(attrs, :status, "assigned"), else: attrs
    Assets.sync_from_mdm(tenant, attrs)
  end

  defp parse_name(nil), do: {"Unknown", "User"}
  defp parse_name(full_name) when is_binary(full_name) do
    parts = String.split(full_name, " ", parts: 2)
    case parts do
      [first, last] -> {first, last}
      [single] -> {single, ""}
      _ -> {"Unknown", "User"}
    end
  end
  defp parse_name(_), do: {"Unknown", "User"}

  defp map_device_to_asset(device) do
    Logger.debug("Mapping device: #{device["deviceName"]} | OS: #{device["operatingSystem"]} | Model: #{inspect(device["model"])} | Manufacturer: #{inspect(device["manufacturer"])}")
    total_storage = device["totalStorageSpaceInBytes"]
    free_storage = device["freeStorageSpaceInBytes"]
    storage_used_percent = if total_storage && total_storage > 0 do
      ((total_storage - free_storage) / total_storage * 100) |> Float.round(1)
    else
      nil
    end

    %{
      name: device["deviceName"],
      asset_tag: device["serialNumber"] || "INTUNE-#{device["id"]}", # Use serial if available
      serial_number: device["serialNumber"],
      model: device["model"],
      make: device["manufacturer"],
      category: categorize_device(device["operatingSystem"]),
      description: "#{device["operatingSystem"]} device managed via Intune | User: #{device["userDisplayName"] || "Unassigned"}",
      os_info: "#{device["operatingSystem"]} #{device["osVersion"]}",
      last_checkin_at: parse_datetime(device["lastSyncDateTime"]),
      purchase_date: parse_datetime(device["enrolledDateTime"]) |> to_date_safe(), # Fallback for purchase date
      custom_fields: %{
        "intune_id" => device["id"],
        "azure_ad_device_id" => device["azureADDeviceId"],
        "managed_device_name" => device["managedDeviceName"],
        "user_display_name" => device["userDisplayName"],
        "user_principal_name" => device["userPrincipalName"],
        "user_id" => device["userId"],
        "compliance_state" => device["complianceState"],
        "management_state" => device["managementState"],
        "device_registration_state" => device["deviceRegistrationState"],
        "is_encrypted" => device["isEncrypted"],
        "is_supervised" => device["isSupervised"],
        "jailbroken_status" => device["jailBroken"],
        "ownership" => device["managedDeviceOwnerType"],
        "enrollment_type" => device["deviceEnrollmentType"],
        "enrolled_date" => device["enrolledDateTime"],
        "enrollment_profile" => device["enrollmentProfileName"],
        "total_storage_gb" => format_bytes_to_gb(total_storage),
        "free_storage_gb" => format_bytes_to_gb(free_storage),
        "storage_used_percent" => storage_used_percent,
        "physical_memory_gb" => format_bytes_to_gb(device["physicalMemoryInBytes"]),
        "wifi_mac_address" => device["wiFiMacAddress"],
        "ethernet_mac_address" => device["ethernetMacAddress"],
        "imei" => device["imei"],
        "meid" => device["meid"],
        "phone_number" => device["phoneNumber"],
        "subscriber_carrier" => device["subscriberCarrier"],
        "partner_threat_state" => device["partnerReportedThreatState"],
        "azure_ad_registered" => device["azureADRegistered"],
        "iccid" => device["iccid"],
        "udid" => device["udid"],
        "android_security_patch" => device["androidSecurityPatchLevel"],
        "device_category" => device["deviceCategoryDisplayName"]
      },
      status: "in_stock"
    }
  end

  defp format_bytes_to_gb(nil), do: nil
  defp format_bytes_to_gb(0), do: 0
  defp format_bytes_to_gb(bytes) when is_integer(bytes) do
    (bytes / 1_073_741_824) |> Float.round(2)
  end
  defp format_bytes_to_gb(_), do: nil

  defp categorize_device(os) do
    os = String.downcase(os || "")
    cond do
      String.contains?(os, "windows") -> "laptop"
      String.contains?(os, "macos") -> "laptop"
      String.contains?(os, "ios") -> "phone"
      String.contains?(os, "android") -> "phone"
      true -> "other"
    end
  end

  defp parse_datetime(nil), do: nil
  defp parse_datetime(iso_string) do
    case DateTime.from_iso8601(iso_string) do
      {:ok, dt, _} -> DateTime.to_naive(dt)
      _ -> nil
    end
  end

  defp to_date_safe(nil), do: nil
  defp to_date_safe(naive) do
    NaiveDateTime.to_date(naive)
  end
end
