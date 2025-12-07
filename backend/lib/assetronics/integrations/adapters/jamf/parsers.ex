defmodule Assetronics.Integrations.Adapters.Jamf.Parsers do
  @moduledoc """
  Data parsing and transformation module for Jamf Pro integration.
  Handles conversion of Jamf API responses to asset attributes.
  """

  @doc """
  Parses computer data from Jamf Pro API response into asset attributes.
  """
  @spec parse_computer(map()) :: map()
  def parse_computer(data) do
    general = data["general"] || %{}
    hardware = data["hardware"] || %{}
    os = data["operatingSystem"] || %{}
    user_and_location = data["userAndLocation"] || %{}
    purchasing = data["purchasing"] || %{}
    storage = data["storage"] || %{}

    %{
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
      assigned_to: user_and_location["realname"] || user_and_location["username"],
      location: user_and_location["building"] || user_and_location["room"],
      purchase_date: parse_date(purchasing["purchaseDate"]),
      purchase_price: parse_price(purchasing["purchasePrice"]),
      vendor: purchasing["vendor"],
      warranty_expires_at: parse_date(purchasing["warrantyDate"]),
      storage_capacity: extract_storage_capacity(storage),
      custom_fields: build_computer_custom_fields(data)
    }
  end

  @doc """
  Parses mobile device data from Jamf Pro API response into asset attributes.
  """
  @spec parse_mobile_device(map()) :: map()
  def parse_mobile_device(data) do
    os_type = data["osType"] || (data["ios"] && "iOS") || "Unknown"
    os_version = data["osVersion"] || data["iosVersion"] || ""

    %{
      name: data["name"] || data["deviceName"] || "Unknown mobile device",
      asset_tag: data["assetTag"] || "JAMF-M-#{data["id"]}",
      serial_number: data["serialNumber"] || "UNKNOWN",
      make: "Apple",
      model: data["model"] || data["modelIdentifier"] || "Unknown",
      category: determine_mobile_category(data["model"] || data["modelIdentifier"] || ""),
      os_info: "#{os_type} #{os_version}",
      last_checkin_at: parse_timestamp(data["lastInventoryUpdate"] || data["lastInventoryUpdateDate"]),
      ip_address: data["ipAddress"],
      mac_address: data["wifiMacAddress"],
      assigned_to: data["username"] || data["userDirectoryID"],
      location: data["building"] || data["site"],
      purchase_date: parse_date(data["purchaseDate"]),
      purchase_price: parse_price(data["purchasePrice"]),
      warranty_expires_at: parse_date(data["warrantyExpiresDate"] || data["warrantyExpiration"]),
      storage_capacity: parse_storage_capacity(data["capacityMb"] || data["capacity"]),
      custom_fields: build_mobile_custom_fields(data)
    }
  end

  @doc """
  Parses an ISO 8601 timestamp string into a NaiveDateTime.
  """
  @spec parse_timestamp(String.t() | nil) :: NaiveDateTime.t() | nil
  def parse_timestamp(nil), do: nil

  def parse_timestamp(iso_str) when is_binary(iso_str) do
    case DateTime.from_iso8601(iso_str) do
      {:ok, dt, _} -> DateTime.to_naive(dt)
      _ -> nil
    end
  end

  def parse_timestamp(_), do: nil

  @doc """
  Parses a date string into ISO 8601 format.
  """
  @spec parse_date(String.t() | nil) :: String.t() | nil
  def parse_date(nil), do: nil

  def parse_date(date_str) when is_binary(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} -> Date.to_iso8601(date)
      _ -> nil
    end
  end

  def parse_date(_), do: nil

  @doc """
  Parses a price value into a float.
  """
  @spec parse_price(term()) :: float() | nil
  def parse_price(nil), do: nil

  def parse_price(price) when is_binary(price) do
    price
    |> String.replace(~r/[$,€£¥]/, "")
    |> String.trim()
    |> Float.parse()
    |> case do
      {amount, _} -> amount
      :error -> nil
    end
  end

  def parse_price(price) when is_number(price), do: price * 1.0
  def parse_price(%Decimal{} = price), do: Decimal.to_float(price)
  def parse_price(_), do: nil

  # Private functions

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
      String.contains?(model, "imac") -> "desktop"
      String.contains?(model, "mac pro") -> "desktop"
      String.contains?(model, "mac mini") -> "desktop"
      String.contains?(model, "mac studio") -> "desktop"
      true -> "laptop"
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

  defp extract_storage_capacity(storage) do
    cond do
      is_map(storage) && storage["disks"] && is_list(storage["disks"]) ->
        storage["disks"]
        |> Enum.at(0)
        |> case do
          %{"sizeMegabytes" => size} when is_number(size) -> "#{size} MB"
          _ -> nil
        end

      true ->
        nil
    end
  end

  defp parse_storage_capacity(nil), do: nil
  defp parse_storage_capacity(mb) when is_number(mb), do: "#{mb} MB"
  defp parse_storage_capacity(_), do: nil

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
      "jamf_id" => data["id"],
      "jamf_udid" => data["udid"],
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
      "os_name" => os["name"],
      "os_version" => os["version"],
      "os_build" => os["build"],
      "os_supplement_build_version" => os["supplementalBuildVersion"],
      "os_rapid_security_response" => os["rapidSecurityResponse"],
      "active_directory_status" => os["activeDirectoryStatus"],
      "software_update_device_id" => os["softwareUpdateDeviceId"],
      "management_id" => get_in(general, ["remoteManagement", "managementId"]),
      "managed" => get_in(general, ["remoteManagement", "managed"]),
      "management_username" => get_in(general, ["remoteManagement", "managementUsername"]),
      "username" => user_and_location["username"],
      "realname" => user_and_location["realname"],
      "email" => user_and_location["email"],
      "position" => user_and_location["position"],
      "phone" => user_and_location["phone"],
      "department" => user_and_location["department"],
      "building" => user_and_location["building"],
      "room" => user_and_location["room"],
      "extension_attributes" => user_and_location["extensionAttributes"],
      "is_purchased" => purchasing["purchased"],
      "is_leased" => purchasing["leased"],
      "po_number" => purchasing["poNumber"],
      "po_date" => purchasing["poDate"],
      "lease_date" => purchasing["leaseDate"],
      "appleCare_id" => purchasing["appleCareId"],
      "life_expectancy" => purchasing["lifeExpectancy"],
      "purchasing_account" => purchasing["purchasingAccount"],
      "purchasing_contact" => purchasing["purchasingContact"],
      "boot_drive_available_mb" => get_in(storage, ["bootDriveAvailableSpaceMegabytes"]),
      "disks" => storage["disks"],
      "activation_lock_enabled" => security["activationLockEnabled"],
      "recovery_lock_enabled" => security["recoveryLockEnabled"],
      "firewall_enabled" => security["firewallEnabled"],
      "secure_boot_level" => security["secureBootLevel"],
      "external_boot_level" => security["externalBootLevel"],
      "xprotect_version" => security["xprotectVersion"],
      "gatekeeper_status" => security["gatekeeperStatus"],
      "sip_status" => security["sipStatus"],
      "boot_partition_encryption_details" => disk_encryption["bootPartitionEncryptionDetails"],
      "individual_recovery_key_validity_status" =>
        disk_encryption["individualRecoveryKeyValidityStatus"],
      "institutional_recovery_key_present" => disk_encryption["institutionalRecoveryKeyPresent"],
      "disk_encryption_configuration_name" => disk_encryption["diskEncryptionConfigurationName"],
      "filevault_enabled" => disk_encryption["fileVault2EligibilityMessage"] == "Enabled",
      "installed_applications" =>
        applications
        |> Enum.take(50)
        |> Enum.map(fn app ->
          %{
            "name" => app["name"],
            "version" => app["version"],
            "path" => app["path"],
            "bundle_id" => app["bundleId"]
          }
        end),
      "software_updates" => data["softwareUpdates"],
      "extension_attributes" => data["extensionAttributes"],
      "groups" => data["groupMemberships"],
      "jamf_raw_data" => data
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
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
      "capacity_mb" => data["capacityMb"],
      "available_mb" => data["availableMb"],
      "percentage_used" => data["percentageUsed"],
      "battery_level" => data["batteryLevel"],
      "bluetooth_mac_address" => data["bluetoothMacAddress"],
      "wifi_mac_address" => data["wifiMacAddress"],
      "model_identifier" => data["modelIdentifier"],
      "model_number" => data["modelNumber"],
      "model_display" => data["modelDisplay"],
      "carrier" => data["currentCarrierNetwork"],
      "home_carrier_network" => data["homeCarrierNetwork"],
      "cellular_technology" => data["cellularTechnology"],
      "phone_number" => data["phoneNumber"],
      "iccid" => data["iccid"],
      "imei" => data["imei"],
      "meid" => data["meid"],
      "os_type" => data["osType"],
      "os_version" => data["osVersion"],
      "os_build" => data["osBuild"],
      "os_supplement_build_version" => data["osSupplementalBuildVersion"],
      "os_rapid_security_response" => data["osRapidSecurityResponse"],
      "software_update_device_id" => data["softwareUpdateDeviceId"],
      "location_services_enabled" => data["locationServicesEnabled"],
      "itunes_store_account_active" => data["itunesStoreAccountActive"],
      "activation_lock_enabled" => data["activationLockEnabled"],
      "do_not_disturb_enabled" => data["doNotDisturbEnabled"],
      "cloud_backup_enabled" => data["cloudBackupEnabled"],
      "last_cloud_backup_date" => data["lastCloudBackupDate"],
      "location_services_for_self_service_mobile_enabled" =>
        data["locationServicesForSelfServiceMobileEnabled"],
      "applications" => data["applications"],
      "app_analytics_enabled" => data["appAnalyticsEnabled"],
      "diagnostic_and_usage_reporting_enabled" => data["diagnosticAndUsageReportingEnabled"],
      "passcode_present" => data["passcodePresent"],
      "passcode_compliant" => data["passcodeCompliant"],
      "passcode_compliant_with_profile" => data["passcodeCompliantWithProfile"],
      "passcode_lock_grace_period_enforced" => data["passcodeLockGracePeriodEnforced"],
      "personal_hotspot_enabled" => data["personalHotspotEnabled"],
      "roaming_enabled" => data["roamingEnabled"],
      "data_roaming_enabled" => data["dataRoamingEnabled"],
      "voice_roaming_enabled" => data["voiceRoamingEnabled"],
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
      "site_id" => data["siteId"],
      "site_name" => data["siteName"],
      "exchange_activesync_device_identifier" => data["exchangeActiveSyncDeviceIdentifier"],
      "profiles" => data["profiles"],
      "certificates" => data["certificates"],
      "configuration_profiles" => data["configurationProfiles"],
      "provisioning_profiles" => data["provisioningProfiles"],
      "network" => data["network"],
      "security" => data["security"],
      "jamf_raw_data" => data
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end
