defmodule Assetronics.Files.Storage.LocalAdapter do
  @moduledoc """
  Local filesystem storage adapter for file uploads.

  Files are stored in the `priv/static/uploads` directory.

  Configuration (config/dev.exs):
  ```
  config :assetronics,
    storage_provider: :local,
    upload_path: "priv/static/uploads"
  ```
  """

  @behaviour Assetronics.Files.Storage.Adapter

  require Logger

  @impl true
  def upload(file_path, destination, _opts \\ []) do
    upload_dir = get_upload_dir()
    full_destination = Path.join(upload_dir, destination)

    # Create directory if it doesn't exist
    destination_dir = Path.dirname(full_destination)
    File.mkdir_p!(destination_dir)

    # Copy file to destination
    case File.cp(file_path, full_destination) do
      :ok ->
        {:ok,
         %{
           storage_provider: "local",
           storage_path: destination
         }}

      {:error, reason} ->
        Logger.error("Failed to copy file to local storage: #{inspect(reason)}")
        {:error, :upload_failed}
    end
  end

  @impl true
  def delete(storage_path) do
    upload_dir = get_upload_dir()
    full_path = Path.join(upload_dir, storage_path)

    case File.rm(full_path) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to delete file from local storage: #{inspect(reason)}")
        {:error, :delete_failed}
    end
  end

  @impl true
  def get_url(storage_path, _opts \\ []) do
    # In development, files are served from /uploads
    # In production with local storage, you'd need to configure a static file server
    url = "/uploads/#{storage_path}"
    {:ok, url}
  end

  # Private functions

  defp get_upload_dir do
    Application.get_env(:assetronics, :upload_path, "priv/static/uploads")
  end
end
