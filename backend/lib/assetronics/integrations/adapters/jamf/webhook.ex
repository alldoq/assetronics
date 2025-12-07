defmodule Assetronics.Integrations.Adapters.Jamf.Webhook do
  @moduledoc """
  Webhook handler module for Jamf Pro integration.
  Processes incoming webhook events for device additions, updates, and deletions.

  Jamf Pro webhook events documentation:
  https://developer.jamf.com/jamf-pro/docs/webhooks

  Supported events:
  - ComputerAdded
  - ComputerCheckIn
  - ComputerInventoryCompleted
  - ComputerPolicyFinished
  - ComputerPushCapabilityChanged
  - MobileDeviceCheckIn
  - MobileDeviceCommandCompleted
  - MobileDeviceEnrolled
  - MobileDevicePushSent
  - MobileDeviceUnEnrolled
  - DeviceAddedToDEP (computer or mobile)
  - DeviceRemovedFromDEP (custom - not a native Jamf event, but can be simulated)
  """

  alias Assetronics.Integrations.Adapters.Jamf.{Api, Auth, ImageHandler, Parsers}
  alias Assetronics.Integrations.Integration
  alias Assetronics.{Assets, Integrations}
  require Logger

  @type webhook_result :: {:ok, map()} | {:error, term()}

  @doc """
  Processes a Jamf Pro webhook event.

  Returns {:ok, result} on success or {:error, reason} on failure.
  """
  @spec process_webhook(String.t(), map(), map()) :: webhook_result()
  def process_webhook(tenant, integration, payload) do
    event_type = payload["webhook"]["webhookEvent"] || payload["event"] || "unknown"
    Logger.info("Processing Jamf webhook event: #{event_type} for tenant #{tenant}")

    case categorize_event(event_type) do
      {:computer, :added} ->
        handle_computer_added(tenant, integration, payload)

      {:computer, :updated} ->
        handle_computer_updated(tenant, integration, payload)

      {:computer, :deleted} ->
        handle_computer_deleted(tenant, integration, payload)

      {:mobile, :added} ->
        handle_mobile_added(tenant, integration, payload)

      {:mobile, :updated} ->
        handle_mobile_updated(tenant, integration, payload)

      {:mobile, :deleted} ->
        handle_mobile_deleted(tenant, integration, payload)

      :unknown ->
        Logger.warning("Unknown Jamf webhook event type: #{event_type}")
        {:ok, %{event: event_type, action: :ignored}}
    end
  end

  @doc """
  Validates the webhook payload structure.
  """
  @spec validate_payload(map()) :: :ok | {:error, String.t()}
  def validate_payload(payload) do
    cond do
      is_nil(payload) ->
        {:error, "Empty payload"}

      is_nil(payload["webhook"]) and is_nil(payload["event"]) ->
        {:error, "Missing webhook event information"}

      true ->
        :ok
    end
  end

  # Event categorization

  defp categorize_event(event_type) do
    case event_type do
      # Computer events
      "ComputerAdded" -> {:computer, :added}
      "DeviceAddedToDEP" -> {:computer, :added}
      "ComputerCheckIn" -> {:computer, :updated}
      "ComputerInventoryCompleted" -> {:computer, :updated}
      "ComputerPolicyFinished" -> {:computer, :updated}
      "ComputerPushCapabilityChanged" -> {:computer, :updated}
      "ComputerDeleted" -> {:computer, :deleted}
      "ComputerUnmanaged" -> {:computer, :deleted}
      # Mobile device events
      "MobileDeviceEnrolled" -> {:mobile, :added}
      "MobileDeviceCheckIn" -> {:mobile, :updated}
      "MobileDeviceCommandCompleted" -> {:mobile, :updated}
      "MobileDevicePushSent" -> {:mobile, :updated}
      "MobileDeviceUnEnrolled" -> {:mobile, :deleted}
      "MobileDeviceDeleted" -> {:mobile, :deleted}
      # Unknown
      _ -> :unknown
    end
  end

  # Computer event handlers

  defp handle_computer_added(tenant, integration, payload) do
    device_data = extract_device_data(payload, :computer)
    jamf_id = device_data["id"] || device_data["jssID"] || device_data["computer_id"]

    if jamf_id do
      Logger.info("Processing computer added event for Jamf ID: #{jamf_id}")
      sync_single_computer(tenant, integration, jamf_id)
    else
      Logger.warning("Computer added event missing device ID")
      {:error, "Missing device ID in webhook payload"}
    end
  end

  defp handle_computer_updated(tenant, integration, payload) do
    device_data = extract_device_data(payload, :computer)
    jamf_id = device_data["id"] || device_data["jssID"] || device_data["computer_id"]

    if jamf_id do
      Logger.info("Processing computer updated event for Jamf ID: #{jamf_id}")
      sync_single_computer(tenant, integration, jamf_id)
    else
      Logger.warning("Computer updated event missing device ID")
      {:error, "Missing device ID in webhook payload"}
    end
  end

  defp handle_computer_deleted(tenant, _integration, payload) do
    device_data = extract_device_data(payload, :computer)
    jamf_id = device_data["id"] || device_data["jssID"] || device_data["computer_id"]
    serial_number = device_data["serialNumber"] || device_data["serial_number"]

    if jamf_id || serial_number do
      Logger.info("Processing computer deleted event for Jamf ID: #{jamf_id || "unknown"}")
      mark_device_as_removed(tenant, jamf_id, serial_number, :computer)
    else
      Logger.warning("Computer deleted event missing device ID and serial number")
      {:error, "Missing device ID and serial number in webhook payload"}
    end
  end

  # Mobile device event handlers

  defp handle_mobile_added(tenant, integration, payload) do
    device_data = extract_device_data(payload, :mobile)
    jamf_id = device_data["id"] || device_data["jssID"] || device_data["device_id"]

    if jamf_id do
      Logger.info("Processing mobile device added event for Jamf ID: #{jamf_id}")
      sync_single_mobile(tenant, integration, jamf_id)
    else
      Logger.warning("Mobile device added event missing device ID")
      {:error, "Missing device ID in webhook payload"}
    end
  end

  defp handle_mobile_updated(tenant, integration, payload) do
    device_data = extract_device_data(payload, :mobile)
    jamf_id = device_data["id"] || device_data["jssID"] || device_data["device_id"]

    if jamf_id do
      Logger.info("Processing mobile device updated event for Jamf ID: #{jamf_id}")
      sync_single_mobile(tenant, integration, jamf_id)
    else
      Logger.warning("Mobile device updated event missing device ID")
      {:error, "Missing device ID in webhook payload"}
    end
  end

  defp handle_mobile_deleted(tenant, _integration, payload) do
    device_data = extract_device_data(payload, :mobile)
    jamf_id = device_data["id"] || device_data["jssID"] || device_data["device_id"]
    serial_number = device_data["serialNumber"] || device_data["serial_number"]

    if jamf_id || serial_number do
      Logger.info("Processing mobile device deleted event for Jamf ID: #{jamf_id || "unknown"}")
      mark_device_as_removed(tenant, jamf_id, serial_number, :mobile)
    else
      Logger.warning("Mobile device deleted event missing device ID and serial number")
      {:error, "Missing device ID and serial number in webhook payload"}
    end
  end

  # Sync helpers

  defp sync_single_computer(tenant, integration, jamf_id) do
    with {:ok, token} <- Auth.get_token(integration),
         {:ok, computer_data} <- fetch_computer_inventory(integration, token, jamf_id) do
      attrs = Parsers.parse_computer(computer_data)
      image_url = ImageHandler.fetch_computer_image(integration, token, jamf_id)
      attrs = Map.put(attrs, :image_url, image_url)

      case Assets.sync_from_mdm(tenant, attrs) do
        {:ok, asset} ->
          Logger.info("Successfully synced computer #{jamf_id} as asset #{asset.id}")
          {:ok, %{action: :synced, asset_id: asset.id, jamf_id: jamf_id}}

        {:error, reason} ->
          Logger.error("Failed to sync computer #{jamf_id}: #{inspect(reason)}")
          {:error, reason}
      end
    else
      {:error, reason} ->
        Logger.error("Failed to fetch computer #{jamf_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp sync_single_mobile(tenant, integration, jamf_id) do
    with {:ok, token} <- Auth.get_token(integration),
         {:ok, mobile_data} <- fetch_mobile_inventory(integration, token, jamf_id) do
      attrs = Parsers.parse_mobile_device(mobile_data)
      image_url = ImageHandler.fetch_mobile_image(integration, token, jamf_id)
      attrs = Map.put(attrs, :image_url, image_url)

      case Assets.sync_from_mdm(tenant, attrs) do
        {:ok, asset} ->
          Logger.info("Successfully synced mobile device #{jamf_id} as asset #{asset.id}")
          {:ok, %{action: :synced, asset_id: asset.id, jamf_id: jamf_id}}

        {:error, reason} ->
          Logger.error("Failed to sync mobile device #{jamf_id}: #{inspect(reason)}")
          {:error, reason}
      end
    else
      {:error, reason} ->
        Logger.error("Failed to fetch mobile device #{jamf_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp fetch_computer_inventory(integration, token, jamf_id) do
    base_url = Auth.normalize_url(integration.auth_config["endpoint"] || integration.base_url)

    sections = [
      "GENERAL",
      "HARDWARE",
      "OPERATING_SYSTEM",
      "DISK_ENCRYPTION",
      "USER_AND_LOCATION",
      "PURCHASING",
      "STORAGE",
      "SECURITY"
    ]

    section_params = Enum.map_join(sections, "&", fn s -> "section=#{s}" end)
    url = "#{base_url}/api/v1/computers-inventory/#{jamf_id}?#{section_params}"
    headers = [Authorization: "Bearer #{token}", Accept: "application/json"]

    case Req.get(url, headers: headers, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_mobile_inventory(integration, token, jamf_id) do
    base_url = Auth.normalize_url(integration.auth_config["endpoint"] || integration.base_url)
    url = "#{base_url}/api/v2/mobile-devices/#{jamf_id}"
    headers = [Authorization: "Bearer #{token}", Accept: "application/json"]

    case Req.get(url, headers: headers, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp mark_device_as_removed(tenant, jamf_id, serial_number, device_type) do
    type_prefix = if device_type == :computer, do: "JAMF-C-", else: "JAMF-M-"

    # Try to find asset by serial number first, then by asset tag
    asset =
      cond do
        serial_number ->
          Assets.get_asset_by_serial_number(tenant, serial_number)

        jamf_id ->
          Assets.get_asset_by_asset_tag(tenant, "#{type_prefix}#{jamf_id}")

        true ->
          nil
      end

    case asset do
      nil ->
        Logger.warning("Could not find asset to mark as removed: jamf_id=#{jamf_id}, serial=#{serial_number}")
        {:ok, %{action: :not_found, jamf_id: jamf_id}}

      asset ->
        # Update the asset to mark it as removed from MDM
        case Assets.update_asset(asset, %{
               custom_fields:
                 Map.merge(asset.custom_fields || %{}, %{
                   "jamf_removed" => true,
                   "jamf_removed_at" => DateTime.utc_now() |> DateTime.to_iso8601()
                 })
             }) do
          {:ok, updated_asset} ->
            Logger.info("Marked asset #{asset.id} as removed from Jamf")
            {:ok, %{action: :marked_removed, asset_id: updated_asset.id, jamf_id: jamf_id}}

          {:error, reason} ->
            Logger.error("Failed to mark asset #{asset.id} as removed: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

  # Payload extraction helpers

  defp extract_device_data(payload, device_type) do
    # Jamf webhooks can have different structures
    cond do
      # Standard webhook format
      payload["webhook"] && payload["webhook"]["event"] ->
        payload["webhook"]["event"]

      # Direct event data
      payload["event"] && is_map(payload["event"]) ->
        payload["event"]

      # Computer-specific fields at root
      device_type == :computer && (payload["computer"] || payload["jssID"]) ->
        payload["computer"] || payload

      # Mobile-specific fields at root
      device_type == :mobile && (payload["mobileDevice"] || payload["jssID"]) ->
        payload["mobileDevice"] || payload

      # Fallback to root payload
      true ->
        payload
    end
  end
end
