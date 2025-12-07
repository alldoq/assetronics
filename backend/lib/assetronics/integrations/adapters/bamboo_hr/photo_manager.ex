defmodule Assetronics.Integrations.Adapters.BambooHR.PhotoManager do
  @moduledoc """
  Manages employee photo downloads and storage for BambooHR integration.

  Handles downloading photos from BambooHR or CloudFront CDN,
  saving them to local storage, and updating employee records with photo URLs.
  """

  alias Assetronics.Employees
  alias Assetronics.Files
  alias Assetronics.Integrations.Adapters.BambooHR.{Api, Client, DataMapper}

  require Logger

  @doc """
  Downloads and stores an employee's photo from BambooHR.

  Skips if photo is already stored locally or if no photo URL is available.
  """
  def download_and_store_photo(tenant, employee, employee_data, integration) do
    photo_url = DataMapper.get_value(employee_data, "photoUrl")

    # Skip if no photo URL
    # Skip if photo is already a local path (starts with /api/ or /uploads/)
    cond do
      is_nil(photo_url) ->
        :skip

      String.contains?(photo_url, "/api/") || String.contains?(photo_url, "/uploads/") ->
        Logger.debug("Photo already stored locally for #{employee.email}")
        :skip

      true ->
        process_photo_download(tenant, employee, photo_url, integration)
    end
  end

  # Private functions

  defp process_photo_download(tenant, employee, photo_url, integration) do
    # BambooHR photoUrl can be relative or absolute
    full_url = build_photo_url(photo_url, integration)

    Logger.info("Downloading employee photo for #{employee.email} from #{full_url}")

    case Api.download_photo(full_url) do
      {:ok, image_data, content_type} ->
        save_and_update_photo(tenant, employee, image_data, content_type)

      {:error, {:http_error, status}} ->
        Logger.warning("Failed to download photo for #{employee.email}: HTTP #{status}")
        :error

      {:error, reason} ->
        Logger.error("Failed to download photo for #{employee.email}: #{inspect(reason)}")
        :error
    end
  end

  defp build_photo_url(photo_url, integration) do
    if String.starts_with?(photo_url, "http") do
      photo_url
    else
      # Make relative URL absolute
      subdomain = Client.get_subdomain(integration)
      "https://#{subdomain}.bamboohr.com#{photo_url}"
    end
  end

  defp save_and_update_photo(tenant, employee, image_data, content_type) do
    ext = DataMapper.get_file_extension(content_type)

    # Save to temporary file
    temp_path = Path.join(System.tmp_dir!(), "bamboo_photo_#{employee.id}_#{:rand.uniform(100000)}.#{ext}")
    File.write!(temp_path, image_data)

    # Upload to our file storage
    upload_attrs = %{
      category: "avatar",
      original_filename: "#{employee.first_name}_#{employee.last_name}.#{ext}",
      content_type: content_type,
      uploaded_by_id: nil, # System upload
      attachable_type: "Employee",
      attachable_id: employee.id
    }

    case Files.upload_file(tenant, temp_path, upload_attrs) do
      {:ok, file} ->
        handle_successful_upload(tenant, employee, file, temp_path)

      {:error, reason} ->
        Logger.error("Failed to upload photo for #{employee.email}: #{inspect(reason)}")
        File.rm(temp_path)
        :error
    end
  end

  defp handle_successful_upload(tenant, employee, file, temp_path) do
    # Get the file URL
    {:ok, url} = Files.get_file_url(file)

    # Update employee with local photo URL
    custom_fields = employee.custom_fields || %{}
    updated_custom_fields = Map.put(custom_fields, "photo_url", url)

    Employees.update_employee(tenant, employee, %{custom_fields: updated_custom_fields})

    # Clean up temp file
    File.rm(temp_path)
    Logger.info("Successfully stored employee photo for #{employee.email}")
    :ok
  end
end