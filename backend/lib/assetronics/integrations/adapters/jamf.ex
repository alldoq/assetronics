defmodule Assetronics.Integrations.Adapters.Jamf do
  @moduledoc """
  Integration adapter for Jamf Pro (MDM for Apple devices).
  Uses the Jamf Pro API (v1) with OAuth 2.0 client credentials flow.
  Extracts comprehensive device data including hardware, software, security,
  purchasing, user information, and device images.
  """
  @behaviour Assetronics.Integrations.Adapter

  alias Assetronics.Integrations.Integration
  alias Assetronics.Assets
  require Logger

  @page_size 100

  @impl true
  def test_connection(%Integration{} = integration) do
    case get_token(integration) do
      {:ok, _token} -> {:ok, %{success: true, message: "Connected to Jamf Pro"}}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def sync(tenant, %Integration{} = integration) do
    with {:ok, token} <- get_token(integration) do
      # 1. Sync Computers
      comp_results = sync_resource(tenant, integration, token, :computers)
      
      # 2. Sync Mobile Devices
      mob_results = sync_resource(tenant, integration, token, :mobiles)
      
      # Aggregate stats
      total_synced = comp_results.synced + mob_results.synced
      total_failed = comp_results.failed + mob_results.failed
      
      {:ok, %{
        assets_synced: total_synced, 
        failed_count: total_failed,
        details: %{computers: comp_results.synced, mobiles: mob_results.synced}
      }}
    else
      error -> error
    end
  end

  # --- Auth ---

  defp get_token(integration) do
    endpoint = normalize_url(integration.auth_config["endpoint"] || integration.base_url)
    client_id = integration.auth_config["client_id"]
    client_secret = integration.auth_config["client_secret"]

    # OAuth 2.0 Client Credentials Flow
    url = "#{endpoint}/api/oauth/token"

    body = %{
      "client_id" => client_id,
      "client_secret" => client_secret,
      "grant_type" => "client_credentials"
    }

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Accept", "application/json"}
    ]

    case Req.post(url, form: body, headers: headers) do
      {:ok, %{status: 200, body: %{"access_token" => token}}} ->
        {:ok, token}
      {:ok, %{status: status, body: body}} ->
        {:error, "Jamf OAuth failed with status #{status}: #{inspect(body)}"}
      {:error, reason} ->
        {:error, "Jamf OAuth connection error: #{inspect(reason)}"}
    end
  end

  # --- Sync Logic ---

  defp sync_resource(tenant, integration, token, type, page \\ 0, acc_stats \\ %{synced: 0, failed: 0}) do
    base_url = normalize_url(integration.auth_config["endpoint"] || integration.base_url)

    {endpoint, section_params} = case type do
      :computers ->
        # Request all available sections for maximum data extraction
        sections = [
          "GENERAL", "HARDWARE", "OPERATING_SYSTEM", "DISK_ENCRYPTION",
          "LOCAL_USER_ACCOUNTS", "USER_AND_LOCATION", "PURCHASING",
          "APPLICATIONS", "STORAGE", "PRINTERS", "SERVICES", "SECURITY",
          "SOFTWARE_UPDATES", "EXTENSION_ATTRIBUTES", "CONTENT_CACHING",
          "GROUP_MEMBERSHIPS", "IBEACONS", "LICENSED_SOFTWARE"
        ]
        section_params = Enum.map_join(sections, "&", fn s -> "section=#{s}" end)
        {"/api/v1/computers-inventory", section_params}
      :mobiles ->
        # Use v2 API for mobile devices inventory
        {"/api/v2/mobile-devices", ""}
    end

    url = "#{base_url}#{endpoint}?page=#{page}&page-size=#{@page_size}&#{section_params}"
    headers = [Authorization: "Bearer #{token}", Accept: "application/json"]

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        items = body["results"] || []
        total_count = body["totalCount"] || 0

        # Process current page
        page_stats = Enum.reduce(items, %{synced: 0, failed: 0}, fn item, stats ->
          result = case type do
            :computers -> process_computer(tenant, integration, token, item)
            :mobiles -> process_mobile(tenant, integration, token, item)
          end

          case result do
            {:ok, _} -> %{stats | synced: stats.synced + 1}
            {:error, reason} ->
              Logger.warning("Failed to sync #{type} item: #{inspect(reason)}")
              %{stats | failed: stats.failed + 1}
          end
        end)

        new_stats = %{
          synced: acc_stats.synced + page_stats.synced,
          failed: acc_stats.failed + page_stats.failed
        }

        # Check for next page
        if (page + 1) * @page_size < total_count do
          sync_resource(tenant, integration, token, type, page + 1, new_stats)
        else
          new_stats
        end

      {:ok, %{status: status, body: body}} ->
        Logger.error("Jamf sync failed for #{type} page #{page}: #{status}")
        Logger.debug("Response body: #{inspect(body)}")
        acc_stats # Return what we have so far

      {:error, reason} ->
        Logger.error("Jamf network error for #{type}: #{inspect(reason)}")
        acc_stats
    end
  end

  defp process_computer(tenant, integration, token, data) do
    general = data["general"] || %{}
    hardware = data["hardware"] || %{}
    os = data["operatingSystem"] || %{}
    user_and_location = data["userAndLocation"] || %{}
    purchasing = data["purchasing"] || %{}
    storage = data["storage"] || %{}
    security = data["security"] || %{}

    # Build comprehensive custom_fields with all available data
    custom_fields = build_computer_custom_fields(data)

    # Download device image if available (non-blocking)
    image_url = try do
      fetch_computer_image(integration, token, data["id"])
    rescue
      e ->
        Logger.error("Failed to fetch image for computer #{data["id"]}: #{inspect(e)}")
        nil
    catch
      :exit, reason ->
        Logger.error("Image fetch timed out for computer #{data["id"]}: #{inspect(reason)}")
        nil
    end

    # Extract core asset fields
    attrs = %{
      name: general["name"],
      asset_tag: general["assetTag"] || "JAMF-C-#{data["id"]}",
      serial_number: hardware["serialNumber"] || "UNKNOWN-#{data["id"]}",
      make: "Apple",
      model: hardware["modelIdentifier"] || hardware["model"],
      category: determine_computer_category(hardware),
      os_info: build_os_info(os),
      last_checkin_at: parse_timestamp(general["lastContactTime"]),
      ip_address: general["lastReportedIp"],
      mac_address: general["macAddress"],

      # User and location data
      assigned_to: user_and_location["realname"] || user_and_location["username"],
      location: user_and_location["building"] || user_and_location["room"],

      # Purchasing data
      purchase_date: parse_date(purchasing["purchaseDate"]),
      purchase_price: parse_price(purchasing["purchasePrice"]),
      vendor: purchasing["vendor"],
      warranty_expires_at: parse_date(purchasing["warrantyDate"]),

      # Storage info
      storage_capacity: extract_storage_capacity(storage),

      # Image
      image_url: image_url,

      # All remaining data in custom_fields
      custom_fields: custom_fields
    }

    Assets.sync_from_mdm(tenant, attrs)
  end

  defp build_computer_custom_fields(data) do
    general = data["general"] || %{}
    hardware = data["hardware"] || %{}
    os = data["operatingSystem"] || %{}
    user_and_location = data["userAndLocation"] || %{}
    purchasing = data["purchasing"] || %{}
    storage = data["storage"] || %{}
    security = data["security"] || %{}
    disk_encryption = data["diskEncryption"] || %{}
    applications = data["applications"] || []

    %{
      # Core identifiers
      "jamf_id" => data["id"],
      "jamf_udid" => data["udid"],

      # General
      "platform" => general["platform"],
      "supervised" => general["supervised"],
      "mdm_capable" => general["mdmCapable"],
      "report_date" => general["reportDate"],
      "last_enrolled" => general["enrolledViaAutomatedDeviceEnrollment"],
      "user_approved_mdm" => general["userApprovedMdm"],
      "declarative_device_management_enabled" => general["declarativeDeviceManagementEnabled"],
      "jamf_binary_version" => general["jamfBinaryVersion"],
      "last_cloud_backup" => general["lastCloudBackupDate"],
      "last_enrolled_date" => general["enrolledViaAutomatedDeviceEnrollment"],
      "site" => general["site"],
      "itunes_store_account_active" => general["itunesStoreAccountActive"],

      # Hardware
      "model" => hardware["model"],
      "model_identifier" => hardware["modelIdentifier"],
      "processor_type" => hardware["processorType"],
      "processor_architecture" => hardware["processorArchitecture"],
      "processor_speed_mhz" => hardware["processorSpeedMhz"],
      "number_processors" => hardware["numberOfProcessors"],
      "number_cores" => hardware["numberOfCores"],
      "total_ram_mb" => hardware["totalRamMegabytes"],
      "battery_capacity" => hardware["batteryCapacityPercent"],
      "smc_version" => hardware["smcVersion"],
      "nic_speed" => hardware["nicSpeed"],
      "optical_drive" => hardware["opticalDrive"],
      "boot_rom" => hardware["bootRom"],
      "bus_speed_mhz" => hardware["busSpeedMhz"],
      "cache_size_kb" => hardware["cacheSizeKilobytes"],
      "supports_ios_app_installs" => hardware["supportsIosAppInstalls"],
      "apple_silicon" => hardware["appleSilicon"],

      # Operating System
      "os_name" => os["name"],
      "os_version" => os["version"],
      "os_build" => os["build"],
      "os_supplement_build_version" => os["supplementalBuildVersion"],
      "os_rapid_security_response" => os["rapidSecurityResponse"],
      "active_directory_status" => os["activeDirectoryStatus"],
      "software_update_device_id" => os["softwareUpdateDeviceId"],

      # Remote Management
      "management_id" => get_in(general, ["remoteManagement", "managementId"]),
      "managed" => get_in(general, ["remoteManagement", "managed"]),
      "management_username" => get_in(general, ["remoteManagement", "managementUsername"]),

      # User and Location
      "username" => user_and_location["username"],
      "realname" => user_and_location["realname"],
      "email" => user_and_location["email"],
      "position" => user_and_location["position"],
      "phone" => user_and_location["phone"],
      "department" => user_and_location["department"],
      "building" => user_and_location["building"],
      "room" => user_and_location["room"],
      "extension_attributes" => user_and_location["extensionAttributes"],

      # Purchasing
      "is_purchased" => purchasing["purchased"],
      "is_leased" => purchasing["leased"],
      "po_number" => purchasing["poNumber"],
      "po_date" => purchasing["poDate"],
      "lease_date" => purchasing["leaseDate"],
      "appleCare_id" => purchasing["appleCareId"],
      "life_expectancy" => purchasing["lifeExpectancy"],
      "purchasing_account" => purchasing["purchasingAccount"],
      "purchasing_contact" => purchasing["purchasingContact"],

      # Storage
      "boot_drive_available_mb" => get_in(storage, ["bootDriveAvailableSpaceMegabytes"]),
      "disks" => storage["disks"],

      # Security
      "activation_lock_enabled" => security["activationLockEnabled"],
      "recovery_lock_enabled" => security["recoveryLockEnabled"],
      "firewall_enabled" => security["firewallEnabled"],
      "secure_boot_level" => security["secureBootLevel"],
      "external_boot_level" => security["externalBootLevel"],
      "xprotect_version" => security["xprotectVersion"],
      "gatekeeper_status" => security["gatekeeperStatus"],
      "sip_status" => security["sipStatus"],

      # Disk Encryption
      "boot_partition_encryption_details" => disk_encryption["bootPartitionEncryptionDetails"],
      "individual_recovery_key_validity_status" => disk_encryption["individualRecoveryKeyValidityStatus"],
      "institutional_recovery_key_present" => disk_encryption["institutionalRecoveryKeyPresent"],
      "disk_encryption_configuration_name" => disk_encryption["diskEncryptionConfigurationName"],
      "filevault_enabled" => disk_encryption["fileVault2EligibilityMessage"] == "Enabled",

      # Applications (first 50 to avoid bloat)
      "installed_applications" => Enum.take(applications, 50) |> Enum.map(fn app ->
        %{
          "name" => app["name"],
          "version" => app["version"],
          "path" => app["path"],
          "bundle_id" => app["bundleId"]
        }
      end),

      # Software Updates
      "software_updates" => data["softwareUpdates"],

      # Extension Attributes
      "extension_attributes" => data["extensionAttributes"],

      # Group Memberships
      "groups" => data["groupMemberships"],

      # All raw data for complete reference
      "jamf_raw_data" => data
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp process_mobile(tenant, integration, token, data) do
    # Build comprehensive custom_fields with all available mobile data
    custom_fields = build_mobile_custom_fields(data)

    # Download device image if available (non-blocking)
    image_url = try do
      fetch_mobile_image(integration, token, data["id"])
    rescue
      e ->
        Logger.error("Failed to fetch image for mobile device #{data["id"]}: #{inspect(e)}")
        nil
    catch
      :exit, reason ->
        Logger.error("Image fetch timed out for mobile device #{data["id"]}: #{inspect(reason)}")
        nil
    end

    # Extract core asset fields - handle both v2 API and Classic API formats
    os_type = data["osType"] || data["ios"] && "iOS" || "Unknown"
    os_version = data["osVersion"] || data["iosVersion"] || ""

    attrs = %{
      name: data["name"] || data["deviceName"] || "Unknown Mobile Device",
      asset_tag: data["assetTag"] || "JAMF-M-#{data["id"]}",
      serial_number: data["serialNumber"] || "UNKNOWN",
      make: "Apple",
      model: data["model"] || data["modelIdentifier"] || "Unknown",
      category: determine_mobile_category(data["model"] || data["modelIdentifier"] || ""),
      os_info: "#{os_type} #{os_version}",
      last_checkin_at: parse_timestamp(data["lastInventoryUpdate"] || data["lastInventoryUpdateDate"]),
      ip_address: data["ipAddress"],
      mac_address: data["wifiMacAddress"],

      # User and location
      assigned_to: data["username"] || data["userDirectoryID"],
      location: data["building"] || data["site"],

      # Purchasing
      purchase_date: parse_date(data["purchaseDate"]),
      purchase_price: parse_price(data["purchasePrice"]),
      warranty_expires_at: parse_date(data["warrantyExpiresDate"] || data["warrantyExpiration"]),

      # Storage
      storage_capacity: parse_storage_capacity(data["capacityMb"] || data["capacity"]),

      # Image
      image_url: image_url,

      # All remaining data in custom_fields
      custom_fields: custom_fields
    }

    Assets.sync_from_mdm(tenant, attrs)
  end

  defp build_mobile_custom_fields(data) do
    %{
      "jamf_id" => data["id"],
      "udid" => data["udid"],
      "device_id" => data["deviceId"],
      "device_name" => data["deviceName"],
      "device_ownership_level" => data["deviceOwnershipLevel"],
      "enrollment_method" => data["enrollmentMethod"],
      "managed" => data["managed"],
      "supervised" => data["supervised"],
      "shared" => data["shared"],

      # Hardware
      "capacity_mb" => data["capacityMb"],
      "available_mb" => data["availableMb"],
      "percentage_used" => data["percentageUsed"],
      "battery_level" => data["batteryLevel"],
      "bluetooth_mac_address" => data["bluetoothMacAddress"],
      "wifi_mac_address" => data["wifiMacAddress"],
      "model_identifier" => data["modelIdentifier"],
      "model_number" => data["modelNumber"],
      "model_display" => data["modelDisplay"],

      # Network
      "carrier" => data["currentCarrierNetwork"],
      "home_carrier_network" => data["homeCarrierNetwork"],
      "cellular_technology" => data["cellularTechnology"],
      "phone_number" => data["phoneNumber"],
      "iccid" => data["iccid"],
      "imei" => data["imei"],
      "meid" => data["meid"],

      # OS
      "os_type" => data["osType"],
      "os_version" => data["osVersion"],
      "os_build" => data["osBuild"],
      "os_supplement_build_version" => data["osSupplementalBuildVersion"],
      "os_rapid_security_response" => data["osRapidSecurityResponse"],
      "software_update_device_id" => data["softwareUpdateDeviceId"],

      # Location Services
      "location_services_enabled" => data["locationServicesEnabled"],
      "itunes_store_account_active" => data["itunesStoreAccountActive"],

      # Activation Lock
      "activation_lock_enabled" => data["activationLockEnabled"],
      "do_not_disturb_enabled" => data["doNotDisturbEnabled"],
      "cloud_backup_enabled" => data["cloudBackupEnabled"],
      "last_cloud_backup_date" => data["lastCloudBackupDate"],
      "location_services_for_self_service_mobile_enabled" => data["locationServicesForSelfServiceMobileEnabled"],

      # Applications
      "applications" => data["applications"],
      "app_analytics_enabled" => data["appAnalyticsEnabled"],
      "diagnostic_and_usage_reporting_enabled" => data["diagnosticAndUsageReportingEnabled"],

      # Security
      "passcode_present" => data["passcodePresent"],
      "passcode_compliant" => data["passcodeCompliant"],
      "passcode_compliant_with_profile" => data["passcodeCompliantWithProfile"],
      "passcode_lock_grace_period_enforced" => data["passcodeLockGracePeriodEnforced"],
      "personal_hotspot_enabled" => data["personalHotspotEnabled"],
      "roaming_enabled" => data["roamingEnabled"],
      "data_roaming_enabled" => data["dataRoamingEnabled"],
      "voice_roaming_enabled" => data["voiceRoamingEnabled"],

      # Lost Mode
      "lost_mode_enabled" => data["lostModeEnabled"],
      "lost_mode_enforced" => data["lostModeEnforced"],
      "lost_mode_enable_issued_epoch" => data["lostModeEnableIssuedEpoch"],
      "lost_mode_message" => data["lostModeMessage"],
      "lost_mode_phone" => data["lostModePhone"],
      "lost_mode_footnote" => data["lostModeFootnote"],
      "lost_location_epoch" => data["lostLocationEpoch"],
      "lost_location_latitude" => data["lostLocationLatitude"],
      "lost_location_longitude" => data["lostLocationLongitude"],
      "lost_location_altitude" => data["lostLocationAltitude"],
      "lost_location_speed" => data["lostLocationSpeed"],
      "lost_location_course" => data["lostLocationCourse"],
      "lost_location_horizontal_accuracy" => data["lostLocationHorizontalAccuracy"],
      "lost_location_vertical_accuracy" => data["lostLocationVerticalAccuracy"],

      # Management
      "site_id" => data["siteId"],
      "site_name" => data["siteName"],

      # Exchange ActiveSync
      "exchange_activesync_device_identifier" => data["exchangeActiveSyncDeviceIdentifier"],

      # Profiles
      "profiles" => data["profiles"],
      "certificates" => data["certificates"],
      "configuration_profiles" => data["configurationProfiles"],
      "provisioning_profiles" => data["provisioningProfiles"],

      # Network
      "network" => data["network"],
      "security" => data["security"],

      # Complete raw data
      "jamf_raw_data" => data
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  # --- Helpers ---

  defp normalize_url(url) do
    url |> String.trim_trailing("/")
  end

  defp parse_timestamp(nil), do: nil
  defp parse_timestamp(iso_str) when is_binary(iso_str) do
    case DateTime.from_iso8601(iso_str) do
      {:ok, dt, _} -> DateTime.to_naive(dt)
      _ -> nil
    end
  end
  defp parse_timestamp(_), do: nil

  defp parse_date(nil), do: nil
  defp parse_date(date_str) when is_binary(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} -> Date.to_iso8601(date)
      _ -> nil
    end
  end
  defp parse_date(_), do: nil

  defp parse_price(nil), do: nil
  defp parse_price(price) when is_binary(price) do
    # Remove currency symbols and parse
    price
    |> String.replace(~r/[$,€£¥]/, "")
    |> String.trim()
    |> Float.parse()
    |> case do
      {amount, _} -> amount
      :error -> nil
    end
  end
  defp parse_price(price) when is_number(price), do: price * 1.0
  defp parse_price(%Decimal{} = price), do: Decimal.to_float(price)
  defp parse_price(_), do: nil

  defp extract_storage_capacity(storage) do
    # Try to get total capacity from storage details
    cond do
      is_map(storage) && storage["disks"] && is_list(storage["disks"]) ->
        storage["disks"]
        |> Enum.at(0)
        |> case do
          %{"sizeMegabytes" => size} when is_number(size) -> "#{size} MB"
          _ -> nil
        end
      true -> nil
    end
  end

  defp parse_storage_capacity(nil), do: nil
  defp parse_storage_capacity(mb) when is_number(mb), do: "#{mb} MB"
  defp parse_storage_capacity(_), do: nil

  defp build_os_info(os) do
    name = os["name"] || ""
    version = os["version"] || ""
    build = os["build"]

    base = "#{name} #{version}" |> String.trim()

    if build do
      "#{base} (#{build})"
    else
      base
    end
  end

  defp determine_computer_category(hardware) do
    model = String.downcase(hardware["model"] || hardware["modelIdentifier"] || "")

    cond do
      String.contains?(model, "macbook") -> "laptop"
      String.contains?(model, "imac") || String.contains?(model, "mac pro") || String.contains?(model, "mac mini") || String.contains?(model, "mac studio") -> "desktop"
      true -> "laptop" # Default for Macs
    end
  end

  defp determine_mobile_category(model) do
    model = String.downcase(model || "")
    cond do
      String.contains?(model, "ipad") -> "tablet"
      String.contains?(model, "iphone") -> "phone"
      String.contains?(model, "ipod") -> "media_player"
      String.contains?(model, "watch") -> "wearable"
      String.contains?(model, "tv") -> "media_device"
      true -> "phone"
    end
  end

  # Fetch computer image from Jamf Pro
  defp fetch_computer_image(integration, token, computer_id) do
    base_url = normalize_url(integration.auth_config["endpoint"] || integration.base_url)

    # Try to get icon from classic API first (more reliable)
    classic_url = "#{base_url}/JSSResource/computers/id/#{computer_id}"
    headers = [Authorization: "Bearer #{token}", Accept: "application/json"]

    Logger.debug("Fetching computer image for computer #{computer_id}")

    case Req.get(classic_url, headers: headers, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        icon_url = case body do
          %{"computer" => %{"general" => %{"icon_url" => url}}} when is_binary(url) -> url
          _ -> nil
        end

        if icon_url do
          Logger.info("Found icon URL for computer #{computer_id}: #{icon_url}")
          # Download and store the icon
          download_image_from_url(integration, token, icon_url, "computer", computer_id)
        else
          Logger.debug("No icon URL in Classic API response for computer #{computer_id}, trying attachments")
          # Try attachments endpoint as fallback
          try_fetch_computer_attachment(integration, token, computer_id, base_url)
        end

      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        # Response is a JSON string, try to parse it
        case Jason.decode(body) do
          {:ok, parsed_body} when is_map(parsed_body) ->
            icon_url = case parsed_body do
              %{"computer" => %{"general" => %{"icon_url" => url}}} when is_binary(url) -> url
              _ -> nil
            end

            if icon_url do
              Logger.info("Found icon URL for computer #{computer_id}: #{icon_url}")
              download_image_from_url(integration, token, icon_url, "computer", computer_id)
            else
              Logger.debug("No icon URL in parsed Classic API response for computer #{computer_id}, trying attachments")
              try_fetch_computer_attachment(integration, token, computer_id, base_url)
            end

          {:error, _} ->
            Logger.debug("Failed to parse Classic API JSON for computer #{computer_id}, trying attachments")
            try_fetch_computer_attachment(integration, token, computer_id, base_url)
        end

      {:ok, %{status: 200, body: _body}} ->
        Logger.debug("Classic API returned unexpected body type for computer #{computer_id}, trying attachments")
        try_fetch_computer_attachment(integration, token, computer_id, base_url)

      {:ok, %{status: status}} ->
        Logger.debug("Classic API returned status #{status} for computer #{computer_id}, trying attachments")
        try_fetch_computer_attachment(integration, token, computer_id, base_url)

      {:error, reason} ->
        Logger.debug("Classic API error for computer #{computer_id}: #{inspect(reason)}, trying attachments")
        try_fetch_computer_attachment(integration, token, computer_id, base_url)
    end
  end

  defp try_fetch_computer_attachment(integration, token, computer_id, base_url) do
    url = "#{base_url}/api/v1/computers-inventory/#{computer_id}/attachments"
    headers = [Authorization: "Bearer #{token}", Accept: "application/json"]

    case Req.get(url, headers: headers, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        case body["results"] do
          [first_attachment | _] ->
            Logger.info("Found attachment for computer #{computer_id}: #{first_attachment["id"]}")
            download_and_store_image(integration, token, first_attachment["id"], "computer", computer_id)
          _ ->
            Logger.debug("No attachments found for computer #{computer_id}")
            nil
        end
      {:ok, %{status: 405}} ->
        # Method Not Allowed - attachments endpoint not available, skip silently
        nil
      {:ok, %{status: status}} when status in [404, 403] ->
        # Expected cases - no attachments or no permission
        nil
      {:ok, %{status: status}} ->
        Logger.debug("Attachments endpoint returned status #{status} for computer #{computer_id}")
        nil
      {:error, reason} ->
        Logger.debug("Error fetching attachments for computer #{computer_id}: #{inspect(reason)}")
        nil
    end
  end

  # Fetch mobile device image from Jamf Pro
  defp fetch_mobile_image(integration, token, device_id) do
    base_url = normalize_url(integration.auth_config["endpoint"] || integration.base_url)
    url = "#{base_url}/JSSResource/mobiledevices/id/#{device_id}"
    headers = [Authorization: "Bearer #{token}", Accept: "application/json"]

    Logger.debug("Fetching mobile device image for device #{device_id}")

    case Req.get(url, headers: headers, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        icon_url = case body do
          %{"mobile_device" => %{"general" => %{"icon_url" => url}}} when is_binary(url) -> url
          _ -> nil
        end

        if icon_url do
          Logger.info("Found icon URL for mobile device #{device_id}: #{icon_url}")
          download_image_from_url(integration, token, icon_url, "mobile", device_id)
        else
          Logger.debug("No icon URL found for mobile device #{device_id}")
          nil
        end

      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        # Response is a JSON string, try to parse it
        case Jason.decode(body) do
          {:ok, parsed_body} when is_map(parsed_body) ->
            icon_url = case parsed_body do
              %{"mobile_device" => %{"general" => %{"icon_url" => url}}} when is_binary(url) -> url
              _ -> nil
            end

            if icon_url do
              Logger.info("Found icon URL for mobile device #{device_id}: #{icon_url}")
              download_image_from_url(integration, token, icon_url, "mobile", device_id)
            else
              Logger.debug("No icon URL in parsed response for mobile device #{device_id}")
              nil
            end

          {:error, _} ->
            Logger.debug("Failed to parse Classic API JSON for mobile device #{device_id}")
            nil
        end

      {:ok, %{status: 200, body: _body}} ->
        Logger.debug("Classic API returned unexpected body type for mobile device #{device_id}")
        nil

      {:ok, %{status: status}} ->
        Logger.debug("Failed to fetch mobile device info, status: #{status}")
        nil

      {:error, reason} ->
        Logger.debug("Error fetching mobile device: #{inspect(reason)}")
        nil
    end
  end

  # Download image from a URL (for icons provided by Jamf)
  defp download_image_from_url(integration, token, image_url, type, device_id) do
    Logger.info("Downloading image from URL: #{image_url}")

    # The URL might be relative or absolute
    full_url = if String.starts_with?(image_url, "http") do
      image_url
    else
      base_url = normalize_url(integration.auth_config["endpoint"] || integration.base_url)
      "#{base_url}#{image_url}"
    end

    headers = [Authorization: "Bearer #{token}"]

    case Req.get(full_url, headers: headers, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: image_data, headers: response_headers}} ->
        content_type = get_content_type(response_headers)
        extension = get_extension_from_content_type(content_type)

        # Create temporary file
        temp_dir = System.tmp_dir!()
        filename = "jamf_#{type}_#{device_id}#{extension}"
        temp_path = Path.join(temp_dir, filename)

        Logger.debug("Writing image to temp file: #{temp_path}")

        case File.write(temp_path, image_data) do
          :ok ->
            storage_dest = "jamf/#{type}/#{device_id}/#{filename}"
            Logger.debug("Uploading to storage: #{storage_dest}")

            case upload_to_storage(temp_path, storage_dest, content_type) do
              {:ok, url} ->
                File.rm(temp_path)
                Logger.info("Successfully stored image at: #{url}")
                url
              {:error, reason} ->
                Logger.error("Failed to upload image: #{inspect(reason)}")
                File.rm(temp_path)
                nil
            end
          {:error, reason} ->
            Logger.error("Failed to write temp file: #{inspect(reason)}")
            nil
        end

      {:ok, %{status: status}} ->
        Logger.warning("Failed to download image, status: #{status}")
        nil

      {:error, reason} ->
        Logger.error("Error downloading image: #{inspect(reason)}")
        nil
    end
  end

  defp download_and_store_image(integration, token, attachment_id, type, device_id) do
    base_url = normalize_url(integration.auth_config["endpoint"] || integration.base_url)

    # Download image from Jamf
    download_url = "#{base_url}/api/v1/computers-inventory/#{device_id}/attachments/#{attachment_id}/download"
    headers = [Authorization: "Bearer #{token}"]

    case Req.get(download_url, headers: headers, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: image_data, headers: response_headers}} ->
        # Get content type from response headers
        content_type = get_content_type(response_headers)
        extension = get_extension_from_content_type(content_type)

        # Create temporary file
        temp_dir = System.tmp_dir!()
        filename = "jamf_#{type}_#{device_id}_#{attachment_id}#{extension}"
        temp_path = Path.join(temp_dir, filename)

        # Write image to temp file
        case File.write(temp_path, image_data) do
          :ok ->
            # Upload to storage
            storage_dest = "jamf/#{type}/#{device_id}/#{filename}"

            case upload_to_storage(temp_path, storage_dest, content_type) do
              {:ok, url} ->
                # Clean up temp file
                File.rm(temp_path)
                url
              {:error, reason} ->
                Logger.error("Failed to upload image to storage: #{inspect(reason)}")
                File.rm(temp_path)
                nil
            end
          {:error, reason} ->
            Logger.error("Failed to write temp file: #{inspect(reason)}")
            nil
        end

      {:ok, %{status: status}} ->
        Logger.warning("Failed to download Jamf image, status: #{status}")
        nil

      {:error, reason} ->
        Logger.error("Error downloading Jamf image: #{inspect(reason)}")
        nil
    end
  end

  defp get_content_type(headers) do
    headers
    |> Enum.find(fn {key, _value} -> String.downcase(key) == "content-type" end)
    |> case do
      {_key, value} -> value
      nil -> "image/png"
    end
  end

  defp get_extension_from_content_type(content_type) do
    case content_type do
      "image/jpeg" -> ".jpg"
      "image/png" -> ".png"
      "image/gif" -> ".gif"
      "image/webp" -> ".webp"
      _ -> ".jpg"
    end
  end

  defp upload_to_storage(file_path, destination, content_type) do
    storage_provider = Application.get_env(:assetronics, :storage_provider, :local)

    case storage_provider do
      :s3 ->
        alias Assetronics.Files.Storage.S3Adapter

        case S3Adapter.upload(file_path, destination, content_type: content_type, acl: :public_read) do
          {:ok, storage_info} ->
            # Get public URL
            case S3Adapter.get_url(storage_info.storage_path, public: true) do
              {:ok, url} -> {:ok, url}
              {:error, _} -> {:error, :url_generation_failed}
            end
          {:error, reason} -> {:error, reason}
        end

      :local ->
        # For local storage, copy to priv/static/uploads
        uploads_dir = Path.join([:code.priv_dir(:assetronics), "static", "uploads"])
        File.mkdir_p!(uploads_dir)

        dest_path = Path.join(uploads_dir, destination)
        dest_dir = Path.dirname(dest_path)
        File.mkdir_p!(dest_dir)

        case File.copy(file_path, dest_path) do
          {:ok, _} -> {:ok, "/uploads/#{destination}"}
          {:error, reason} -> {:error, reason}
        end

      _ ->
        {:error, :unsupported_storage_provider}
    end
  end
end
