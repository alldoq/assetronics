defmodule Assetronics.Integrations.Adapters.GoogleWorkspace do
  @moduledoc """
  Integration adapter for Google Workspace.

  Features:
  - Service Account JWT authentication via Goth
  - ChromeOS Device sync
  - Mobile Device sync (iOS & Android)
  - Google Workspace license management
  - User directory sync for employee mapping
  - Intelligent deduplication based on device IDs
  """

  @behaviour Assetronics.Integrations.Adapter

  alias Assetronics.Integrations.Integration
  alias Assetronics.Assets
  alias Assetronics.Employees
  require Logger

  @customer_id "my_customer"
  @max_results_chromeos 200
  @max_results_mobile 100  # Mobile API has a lower limit
  @required_scopes [
    "https://www.googleapis.com/auth/admin.directory.device.chromeos",
    "https://www.googleapis.com/auth/admin.directory.device.mobile",
    "https://www.googleapis.com/auth/admin.directory.user.readonly",
    "https://www.googleapis.com/auth/apps.licensing"
  ]

  @impl true
  def test_connection(%Integration{} = integration) do
    case get_access_token(integration) do
      {:ok, token} ->
        # Test by fetching a small sample of devices
        test_url = "https://admin.googleapis.com/admin/directory/v1/customer/#{@customer_id}/devices/chromeos?maxResults=1"

        case Req.get(test_url, headers: authorization_headers(token)) do
          {:ok, %{status: 200}} ->
            {:ok, %{success: true, message: "Connection successful"}}
          {:ok, %{status: status, body: body}} ->
            {:error, "Connection test failed with status #{status}: #{inspect(body)}"}
          {:error, reason} ->
            {:error, "Connection failed: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, "Authentication failed: #{inspect(reason)}"}
    end
  end

  @impl true
  def sync(tenant, %Integration{} = integration) do
    Logger.info("Starting Google Workspace sync for tenant: #{tenant}, integration: #{integration.id}")

    with {:ok, token} <- get_access_token(integration) do
      Logger.info("Successfully obtained Google Workspace access token")

      # Run syncs in parallel for better performance
      tasks = [
        Task.async(fn -> sync_chromeos_devices(tenant, integration, token) end),
        Task.async(fn -> sync_mobile_devices(tenant, integration, token) end),
        Task.async(fn -> sync_licenses(tenant, integration, token) end)
      ]

      results = Task.await_many(tasks, 30_000) # 30 second timeout

      # Aggregate results
      aggregated = Enum.reduce(results, %{
        chromeos_synced: 0,
        mobile_synced: 0,
        licenses_synced: 0,
        errors: []
      }, fn result, acc ->
        case result do
          {:ok, counts} -> Map.merge(acc, counts)
          {:error, error} ->
            Logger.error("Google Workspace sync error: #{inspect(error)}")
            Map.update(acc, :errors, [error], &[error | &1])
        end
      end)

      Logger.info("Google Workspace sync completed: #{inspect(aggregated)}")

      if Enum.empty?(aggregated.errors) do
        {:ok, aggregated}
      else
        {:ok, Map.put(aggregated, :partial_success, true)}
      end
    else
      {:error, reason} ->
        Logger.error("Google Workspace authentication failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Authentication
  defp get_access_token(%Integration{} = integration) do
    Logger.debug("Getting Google Workspace access token...")
    Logger.debug("Auth config present: #{!is_nil(integration.auth_config)}")

    cond do
      # Option 1: Service Account JSON stored in auth_config
      integration.auth_config["service_account_json"] ->
        Logger.info("Using service account JSON for authentication")
        get_token_from_service_account(
          integration.auth_config["service_account_json"],
          integration.auth_config["admin_email"]
        )

      # Option 2: Direct access token (for testing/development)
      integration.access_token && integration.access_token != "" ->
        Logger.info("Using direct access token for authentication")
        {:ok, integration.access_token}

      true ->
        Logger.error("No authentication method configured for Google Workspace")
        Logger.error("Auth config: #{inspect(integration.auth_config)}")
        Logger.error("Access token present: #{!is_nil(integration.access_token)}")
        {:error, "No authentication method configured"}
    end
  end

  # Fetch OAuth token using Google Service Account JWT flow
  # This implements the flow described at:
  # https://developers.google.com/identity/protocols/oauth2/service-account
  defp fetch_service_account_token(credentials, scopes, subject \\ nil) do
    now = System.system_time(:second)

    # Build JWT claims
    claims = %{
      "iss" => credentials["client_email"],
      "scope" => Enum.join(scopes, " "),
      "aud" => "https://oauth2.googleapis.com/token",
      "exp" => now + 3600,
      "iat" => now
    }

    # Add subject claim if provided (for domain-wide delegation)
    claims = if subject, do: Map.put(claims, "sub", subject), else: claims

    # Sign JWT with private key
    case sign_jwt(claims, credentials["private_key"]) do
      {:ok, jwt} ->
        # Exchange JWT for access token
        exchange_jwt_for_token(jwt)

      {:error, reason} ->
        {:error, "Failed to sign JWT: #{inspect(reason)}"}
    end
  end

  # Sign JWT using RS256 algorithm
  defp sign_jwt(claims, private_key_pem) do
    try do
      # Parse PEM private key
      [entry] = :public_key.pem_decode(private_key_pem)
      private_key = :public_key.pem_entry_decode(entry)

      # Create JWT header
      header = %{
        "alg" => "RS256",
        "typ" => "JWT"
      }

      # Encode header and payload
      encoded_header = header |> Jason.encode!() |> Base.url_encode64(padding: false)
      encoded_claims = claims |> Jason.encode!() |> Base.url_encode64(padding: false)

      # Create signature
      message = "#{encoded_header}.#{encoded_claims}"
      signature = :public_key.sign(message, :sha256, private_key)
      encoded_signature = Base.url_encode64(signature, padding: false)

      # Combine into JWT
      jwt = "#{message}.#{encoded_signature}"

      {:ok, jwt}
    rescue
      e ->
        Logger.error("JWT signing error: #{inspect(e)}")
        {:error, e}
    end
  end

  # Exchange signed JWT for OAuth access token
  defp exchange_jwt_for_token(jwt) do
    body = %{
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt
    }

    case Req.post("https://oauth2.googleapis.com/token", form: body) do
      {:ok, %{status: 200, body: %{"access_token" => token}}} ->
        {:ok, token}

      {:ok, %{status: status, body: body}} ->
        {:error, "Token exchange failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Token exchange request failed: #{inspect(reason)}"}
    end
  end

  defp get_token_from_service_account(service_account_json, admin_email \\ nil) do
    Logger.debug("Parsing service account JSON...")

    # Parse the service account JSON
    case Jason.decode(service_account_json) do
      {:ok, credentials} ->
        Logger.info("Service account JSON parsed successfully")
        Logger.debug("Project ID: #{credentials["project_id"]}")
        Logger.debug("Client email: #{credentials["client_email"]}")

        # For Google Workspace Admin APIs, we REQUIRE domain-wide delegation
        # The subject must be an admin email address from the Google Workspace domain
        subject_email = admin_email

        if is_nil(subject_email) or subject_email == "" do
          Logger.error("Admin email is required for Google Workspace integration")
          Logger.error("Please add an admin email to auth_config['admin_email']")
          {:error, "Admin email required. Add an admin user email to the integration configuration."}
        else
          Logger.info("Using domain-wide delegation with subject: #{subject_email}")
          Logger.debug("Fetching OAuth token using Service Account...")

          # Fetch token with admin impersonation
          fetch_service_account_token(credentials, @required_scopes, subject_email)
        end

      {:error, reason} ->
        Logger.error("Failed to parse service account JSON: #{inspect(reason)}")
        {:error, "Invalid service account JSON: #{inspect(reason)}"}
    end
  end

  # ChromeOS Device Sync
  defp sync_chromeos_devices(tenant, _integration, token) do
    case fetch_all_chromeos_devices(token) do
      {:ok, devices} ->
        results = Enum.map(devices, fn device ->
          process_chromeos_device(tenant, device)
        end)

        success_count = Enum.count(results, fn {status, _} -> status == :ok end)
        Logger.info("Google Workspace: Synced #{success_count} ChromeOS devices")

        {:ok, %{chromeos_synced: success_count}}

      {:error, reason} ->
        Logger.error("Failed to sync ChromeOS devices: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp fetch_all_chromeos_devices(token, page_token \\ nil, accumulated \\ []) do
    url = build_url("/customer/#{@customer_id}/devices/chromeos", %{
      projection: "FULL",
      maxResults: @max_results_chromeos,
      pageToken: page_token
    })

    Logger.debug("Fetching ChromeOS devices from: #{url}")

    case Req.get(url, headers: authorization_headers(token)) do
      {:ok, %{status: 200, body: body}} ->
        devices = Map.get(body, "chromeosdevices", [])
        Logger.info("Fetched #{length(devices)} ChromeOS devices (page)")
        all_devices = accumulated ++ devices

        case Map.get(body, "nextPageToken") do
          nil -> {:ok, all_devices}
          next_token -> fetch_all_chromeos_devices(token, next_token, all_devices)
        end

      {:ok, %{status: status, body: body}} ->
        Logger.error("Failed to fetch ChromeOS devices: HTTP #{status}")
        Logger.error("Response body: #{inspect(body)}")
        {:error, "Failed to fetch ChromeOS devices: #{status} - #{inspect(body)}"}

      {:error, reason} ->
        Logger.error("HTTP request failed for ChromeOS devices: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp process_chromeos_device(tenant, device) do
    # Use a consistent unique identifier for deduplication
    # Prefer serial number, but fall back to device ID
    # NOTE: Check for empty strings too, not just nil
    unique_id = first_non_empty([device["serialNumber"], device["deviceId"]])

    # Extract device information
    attrs = %{
      name: device["annotatedAssetId"] || device["serialNumber"] || "ChromeOS-#{device["deviceId"]}",
      asset_tag: device["annotatedAssetId"] || generate_asset_tag("GW-CB", device),
      serial_number: unique_id,  # Ensure we always have a unique identifier
      model: device["model"],
      make: extract_manufacturer(device["model"]),
      category: "laptop",
      os_info: build_os_info(device),
      last_checkin_at: parse_datetime(device["lastSync"]),
      purchase_date: parse_datetime(device["firstEnrollmentTime"]),
      custom_fields: %{
        "google_device_id" => device["deviceId"],
        "actual_serial_number" => device["serialNumber"],  # Store the real serial if available
        "google_status" => device["status"],
        "annotated_user" => device["annotatedUser"],
        "annotated_location" => device["annotatedLocation"],
        "mac_address" => device["macAddress"],
        "ethernet_mac" => device["ethernetMacAddress"],
        "firmware_version" => device["firmwareVersion"],
        "auto_update_expiration" => device["autoUpdateExpiration"]
      },
      status: map_device_status(device["status"]),
      location: device["annotatedLocation"],
      notes: device["notes"]
    }

    # Add hardware specifications if available
    attrs = attrs
    |> add_if_present(:cpu_info, format_cpu_info(device))
    |> add_if_present(:memory_info, format_memory_info(device))
    |> add_if_present(:storage_info, format_storage_info(device))

    # Map to employee
    attrs = map_to_employee(tenant, attrs, device)

    # Use deduplication-aware sync
    Assets.sync_from_mdm(tenant, attrs)
  end

  # Mobile Device Sync
  defp sync_mobile_devices(tenant, _integration, token) do
    case fetch_all_mobile_devices(token) do
      {:ok, devices} ->
        results = Enum.map(devices, fn device ->
          process_mobile_device(tenant, device)
        end)

        success_count = Enum.count(results, fn {status, _} -> status == :ok end)
        Logger.info("Google Workspace: Synced #{success_count} mobile devices")

        {:ok, %{mobile_synced: success_count}}

      {:error, reason} ->
        Logger.error("Failed to sync mobile devices: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp fetch_all_mobile_devices(token, page_token \\ nil, accumulated \\ []) do
    url = build_url("/customer/#{@customer_id}/devices/mobile", %{
      projection: "FULL",
      maxResults: @max_results_mobile,
      pageToken: page_token
    })

    case Req.get(url, headers: authorization_headers(token)) do
      {:ok, %{status: 200, body: body}} ->
        devices = Map.get(body, "mobiledevices", [])
        all_devices = accumulated ++ devices

        case Map.get(body, "nextPageToken") do
          nil -> {:ok, all_devices}
          next_token -> fetch_all_mobile_devices(token, next_token, all_devices)
        end

      {:ok, %{status: status, body: body}} ->
        {:error, "Failed to fetch mobile devices: #{status} - #{inspect(body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp process_mobile_device(tenant, device) do
    category = determine_mobile_category(device)

    # Use a consistent unique identifier for deduplication
    # Prefer serial number, but fall back to a consistent ID
    # NOTE: Check for empty strings too, not just nil
    unique_id = first_non_empty([
      device["serialNumber"],
      device["imei"],
      device["meid"],
      device["deviceId"],
      device["resourceId"]
    ])

    Logger.debug("Processing mobile device: #{inspect(device["deviceId"])}")
    Logger.debug("  Serial: #{device["serialNumber"]}, IMEI: #{device["imei"]}, MEID: #{device["meid"]}")
    Logger.debug("  Using unique_id for deduplication: #{unique_id}")

    attrs = %{
      name: build_mobile_name(device),
      asset_tag: generate_asset_tag("GW-M", device),
      serial_number: unique_id,  # Ensure we always have a unique identifier
      model: device["model"],
      make: device["manufacturer"] || device["brand"],
      category: category,
      os_info: "#{device["os"]} #{device["osVersion"]}",
      last_checkin_at: parse_datetime(device["lastSync"]),
      custom_fields: %{
        "google_resource_id" => device["resourceId"],
        "google_device_id" => device["deviceId"],
        "actual_serial_number" => device["serialNumber"],  # Store the real serial if available
        "google_status" => device["status"],
        "imei" => device["imei"],
        "meid" => device["meid"],
        "wifi_mac" => device["wifiMacAddress"],
        "network_operator" => device["networkOperator"],
        "device_type" => device["type"],
        "hardware_info" => device["hardware"],
        "kernel_version" => device["kernelVersion"],
        "baseband_version" => device["basebandVersion"],
        "build_number" => device["buildNumber"],
        "security_patch_level" => device["securityPatchLevel"],
        "encryption_status" => device["encryptionStatus"],
        "device_compromised_status" => device["deviceCompromisedStatus"]
      },
      status: map_device_status(device["status"]),
      notes: "Mobile device managed via Google Workspace"
    }

    # Map user email to employee
    # The email field can be a list, so we get the first element
    email_list = device["email"] || []
    email = if is_list(email_list), do: List.first(email_list), else: email_list

    attrs = if email && email != "" do
      map_user_to_employee(tenant, attrs, email)
    else
      attrs
    end

    Assets.sync_from_mdm(tenant, attrs)
  end

  # License Management Sync
  defp sync_licenses(tenant, _integration, token) do
    product_ids = [
      "Google-Apps",
      "101001",  # Business Starter
      "101005",  # Business Standard
      "101009",  # Business Plus
      "1010020", # Enterprise Standard
      "1010060"  # Enterprise Plus
    ]

    license_results = Enum.flat_map(product_ids, fn product_id ->
      case fetch_licenses_for_product(token, product_id) do
        {:ok, licenses} -> licenses
        {:error, _} -> []
      end
    end)

    # Group licenses by user
    licenses_by_user = Enum.group_by(license_results, & &1["userId"])

    # Process license data (could be stored in a separate licenses table or custom fields)
    Enum.each(licenses_by_user, fn {user_email, licenses} ->
      process_user_licenses(tenant, user_email, licenses)
    end)

    {:ok, %{licenses_synced: map_size(licenses_by_user)}}
  end

  defp fetch_licenses_for_product(token, product_id, page_token \\ nil, accumulated \\ []) do
    url = "https://www.googleapis.com/apps/licensing/v1/product/#{product_id}/users"

    params = %{
      customerId: @customer_id,
      maxResults: 1000
    }

    params = if page_token, do: Map.put(params, :pageToken, page_token), else: params

    case Req.get(url, headers: authorization_headers(token), params: params) do
      {:ok, %{status: 200, body: body}} ->
        items = Map.get(body, "items", [])
        all_items = accumulated ++ items

        case Map.get(body, "nextPageToken") do
          nil -> {:ok, all_items}
          next_token -> fetch_licenses_for_product(token, product_id, next_token, all_items)
        end

      {:ok, %{status: 404}} ->
        # Product not available for this customer
        {:ok, []}

      {:ok, %{status: 403, body: body}} ->
        error_message = get_in(body, ["error", "message"]) || "Access denied"
        Logger.warning("License API 403 for product #{product_id}: #{error_message}")
        Logger.warning("Make sure:")
        Logger.warning("  1. Google Workspace License Manager API is enabled")
        Logger.warning("  2. Scope 'https://www.googleapis.com/auth/apps.licensing' is authorized in domain-wide delegation")
        Logger.warning("  3. The admin email has permission to view licenses")
        {:error, body}

      {:ok, %{status: status, body: body}} ->
        Logger.warning("Failed to fetch licenses for product #{product_id}: #{status}")
        {:error, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp process_user_licenses(tenant, user_email, licenses) do
    # Find the employee
    case Employees.get_employee_by_email(tenant, user_email) do
      {:ok, employee} ->
        # Store license information in employee's custom fields or related table
        license_summary = Enum.map(licenses, fn license ->
          %{
            product_id: license["productId"],
            sku_id: license["skuId"],
            sku_name: license["skuName"]
          }
        end)

        # Update employee with license data
        Employees.update_employee(tenant, employee, %{
          custom_fields: Map.put(employee.custom_fields || %{}, "google_licenses", license_summary)
        })

      _ ->
        Logger.debug("No employee found for Google user: #{user_email}")
    end
  end

  # Helper Functions

  # Get first non-empty value from a list
  # Returns nil if all values are nil or empty strings
  defp first_non_empty(list) do
    Enum.find(list, fn val ->
      val != nil && val != ""
    end)
  end

  defp authorization_headers(token) do
    [
      Authorization: "Bearer #{token}",
      Accept: "application/json"
    ]
  end

  defp build_url(path, params) do
    base_url = "https://admin.googleapis.com/admin/directory/v1#{path}"

    query_string =
      params
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> URI.encode_query()

    if query_string == "" do
      base_url
    else
      "#{base_url}?#{query_string}"
    end
  end

  defp map_device_status("ACTIVE"), do: "assigned"
  defp map_device_status("DISABLED"), do: "retired"
  defp map_device_status("DEPROVISIONED"), do: "retired"
  defp map_device_status("PROVISIONED"), do: "in_stock"
  defp map_device_status(_), do: "in_stock"

  defp parse_datetime(nil), do: nil
  defp parse_datetime(iso_string) do
    case DateTime.from_iso8601(iso_string) do
      {:ok, dt, _} -> DateTime.to_naive(dt)
      _ -> nil
    end
  end

  defp extract_manufacturer(nil), do: "Unknown"
  defp extract_manufacturer(model) do
    cond do
      String.contains?(model, "HP") -> "HP"
      String.contains?(model, "Dell") -> "Dell"
      String.contains?(model, "Lenovo") -> "Lenovo"
      String.contains?(model, "ASUS") -> "ASUS"
      String.contains?(model, "Acer") -> "Acer"
      String.contains?(model, "Samsung") -> "Samsung"
      String.contains?(model, "Google") -> "Google"
      true -> "Unknown"
    end
  end

  defp generate_asset_tag(prefix, device) do
    serial = device["serialNumber"] || device["deviceId"] || UUID.uuid4()
    "#{prefix}-#{String.slice(serial, -8..-1)}"
  end

  defp build_os_info(device) do
    os_version = device["osVersion"] || "Unknown"
    platform_version = device["platformVersion"]

    if platform_version do
      "ChromeOS #{os_version} (Platform: #{platform_version})"
    else
      "ChromeOS #{os_version}"
    end
  end

  defp format_cpu_info(device) do
    case device["cpuStatusReports"] do
      [report | _] ->
        temps = report["cpuTemperatureInfo"]
        if temps && length(temps) > 0 do
          "CPU with #{length(temps)} cores"
        end
      _ -> nil
    end
  end

  defp format_memory_info(device) do
    case device["systemRamTotal"] do
      nil -> nil
      bytes -> "#{div(bytes, 1_073_741_824)} GB RAM"
    end
  end

  defp format_storage_info(device) do
    case device["diskVolumeReports"] do
      [report | _] ->
        bytes = report["volumeInfo"]["storageTotalBytes"] || 0
        "#{div(bytes, 1_073_741_824)} GB Storage"
      _ -> nil
    end
  end

  defp add_if_present(attrs, _key, nil), do: attrs
  defp add_if_present(attrs, key, value), do: Map.put(attrs, key, value)

  defp map_to_employee(tenant, attrs, device) do
    # Try multiple ways to find the user
    user_email = device["annotatedUser"] ||
      case device["recentUsers"] do
        [first_user | _] -> first_user["email"]
        _ -> nil
      end

    if user_email && user_email != "" do
      case Employees.get_employee_by_email(tenant, user_email) do
        {:ok, employee} ->
          attrs
          |> Map.put(:employee_id, employee.id)
          |> Map.put(:status, "assigned")
        _ ->
          attrs
      end
    else
      attrs
    end
  end

  defp map_user_to_employee(tenant, attrs, email) when is_binary(email) do
    case Employees.get_employee_by_email(tenant, email) do
      {:ok, employee} ->
        attrs
        |> Map.put(:employee_id, employee.id)
        |> Map.put(:status, "assigned")
      _ ->
        attrs
    end
  end
  defp map_user_to_employee(_tenant, attrs, _), do: attrs

  defp determine_mobile_category(device) do
    case String.downcase(device["type"] || "") do
      "android" -> "phone"
      "ios" ->
        if String.contains?(String.downcase(device["model"] || ""), "ipad") do
          "tablet"
        else
          "phone"
        end
      _ -> "phone"
    end
  end

  defp build_mobile_name(device) do
    model = device["model"] || "Mobile Device"
    brand = device["brand"] || device["manufacturer"] || ""

    if brand != "" do
      "#{brand} #{model}"
    else
      model
    end
  end
end