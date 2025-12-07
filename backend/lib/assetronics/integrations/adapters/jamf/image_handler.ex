defmodule Assetronics.Integrations.Adapters.Jamf.ImageHandler do
  @moduledoc """
  Image handling module for Jamf Pro integration.
  Handles fetching, downloading, and storing device images.
  """

  alias Assetronics.Integrations.Adapters.Jamf.{Api, Auth}
  alias Assetronics.Integrations.Integration
  require Logger

  @doc """
  Fetches and stores the image for a computer.
  Returns the stored image URL or nil if no image is available.
  """
  @spec fetch_computer_image(Integration.t(), String.t(), String.t() | integer()) ::
          String.t() | nil
  def fetch_computer_image(integration, token, computer_id) do
    try do
      do_fetch_computer_image(integration, token, computer_id)
    rescue
      e ->
        Logger.error("Failed to fetch image for computer #{computer_id}: #{inspect(e)}")
        nil
    catch
      :exit, reason ->
        Logger.error("Image fetch timed out for computer #{computer_id}: #{inspect(reason)}")
        nil
    end
  end

  @doc """
  Fetches and stores the image for a mobile device.
  Returns the stored image URL or nil if no image is available.
  """
  @spec fetch_mobile_image(Integration.t(), String.t(), String.t() | integer()) ::
          String.t() | nil
  def fetch_mobile_image(integration, token, device_id) do
    try do
      do_fetch_mobile_image(integration, token, device_id)
    rescue
      e ->
        Logger.error("Failed to fetch image for mobile device #{device_id}: #{inspect(e)}")
        nil
    catch
      :exit, reason ->
        Logger.error("Image fetch timed out for mobile device #{device_id}: #{inspect(reason)}")
        nil
    end
  end

  # Private functions

  defp do_fetch_computer_image(integration, token, computer_id) do
    Logger.debug("Fetching computer image for computer #{computer_id}")

    case Api.fetch_computer_by_id(integration, token, computer_id) do
      {:ok, body} ->
        icon_url = extract_computer_icon_url(body)

        if icon_url do
          Logger.info("Found icon URL for computer #{computer_id}: #{icon_url}")
          download_and_store_from_url(integration, token, icon_url, "computer", computer_id)
        else
          Logger.debug("No icon URL for computer #{computer_id}, trying attachments")
          try_fetch_computer_attachment(integration, token, computer_id)
        end

      {:error, _reason} ->
        Logger.debug("Failed to fetch computer #{computer_id}, trying attachments")
        try_fetch_computer_attachment(integration, token, computer_id)
    end
  end

  defp do_fetch_mobile_image(integration, token, device_id) do
    Logger.debug("Fetching mobile device image for device #{device_id}")

    case Api.fetch_mobile_device_by_id(integration, token, device_id) do
      {:ok, body} ->
        icon_url = extract_mobile_icon_url(body)

        if icon_url do
          Logger.info("Found icon URL for mobile device #{device_id}: #{icon_url}")
          download_and_store_from_url(integration, token, icon_url, "mobile", device_id)
        else
          Logger.debug("No icon URL found for mobile device #{device_id}")
          nil
        end

      {:error, reason} ->
        Logger.debug("Failed to fetch mobile device #{device_id}: #{inspect(reason)}")
        nil
    end
  end

  defp extract_computer_icon_url(body) do
    case body do
      %{"computer" => %{"general" => %{"icon_url" => url}}} when is_binary(url) -> url
      _ -> nil
    end
  end

  defp extract_mobile_icon_url(body) do
    case body do
      %{"mobile_device" => %{"general" => %{"icon_url" => url}}} when is_binary(url) -> url
      _ -> nil
    end
  end

  defp try_fetch_computer_attachment(integration, token, computer_id) do
    case Api.fetch_computer_attachments(integration, token, computer_id) do
      {:ok, [first_attachment | _]} ->
        Logger.info("Found attachment for computer #{computer_id}: #{first_attachment["id"]}")
        download_and_store_attachment(integration, token, computer_id, first_attachment["id"])

      {:ok, []} ->
        Logger.debug("No attachments found for computer #{computer_id}")
        nil

      {:error, reason} ->
        Logger.debug("Error fetching attachments for computer #{computer_id}: #{inspect(reason)}")
        nil
    end
  end

  defp download_and_store_from_url(integration, token, image_url, type, device_id) do
    Logger.info("Downloading image from URL: #{image_url}")

    full_url =
      if String.starts_with?(image_url, "http") do
        image_url
      else
        base_url = Auth.normalize_url(integration.auth_config["endpoint"] || integration.base_url)
        "#{base_url}#{image_url}"
      end

    case Api.download_file(full_url, token) do
      {:ok, image_data, content_type} ->
        store_image(image_data, content_type, type, device_id)

      {:error, reason} ->
        Logger.warning("Failed to download image: #{inspect(reason)}")
        nil
    end
  end

  defp download_and_store_attachment(integration, token, computer_id, attachment_id) do
    base_url = Auth.normalize_url(integration.auth_config["endpoint"] || integration.base_url)

    download_url =
      "#{base_url}/api/v1/computers-inventory/#{computer_id}/attachments/#{attachment_id}/download"

    case Api.download_file(download_url, token) do
      {:ok, image_data, content_type} ->
        store_image(image_data, content_type, "computer", computer_id, attachment_id)

      {:error, reason} ->
        Logger.warning("Failed to download attachment: #{inspect(reason)}")
        nil
    end
  end

  defp store_image(image_data, content_type, type, device_id, attachment_id \\ nil) do
    extension = get_extension_from_content_type(content_type)
    temp_dir = System.tmp_dir!()

    filename =
      if attachment_id do
        "jamf_#{type}_#{device_id}_#{attachment_id}#{extension}"
      else
        "jamf_#{type}_#{device_id}#{extension}"
      end

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
            case S3Adapter.get_url(storage_info.storage_path, public: true) do
              {:ok, url} -> {:ok, url}
              {:error, _} -> {:error, :url_generation_failed}
            end

          {:error, reason} ->
            {:error, reason}
        end

      :local ->
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
