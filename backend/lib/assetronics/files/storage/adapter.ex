defmodule Assetronics.Files.Storage.Adapter do
  @moduledoc """
  Behavior for file storage adapters.

  Supports multiple storage backends:
  - Local filesystem (development)
  - AWS S3 (production)
  """

  @doc """
  Uploads a file to storage.

  ## Parameters
  - file_path: Path to the local file
  - destination: Destination path in storage
  - opts: Additional options (content_type, metadata, etc.)

  ## Returns
  - {:ok, storage_info} - Map with storage location details
  - {:error, reason}
  """
  @callback upload(file_path :: String.t(), destination :: String.t(), opts :: keyword()) ::
              {:ok, map()} | {:error, any()}

  @doc """
  Deletes a file from storage.

  ## Parameters
  - storage_path: Path to the file in storage

  ## Returns
  - :ok
  - {:error, reason}
  """
  @callback delete(storage_path :: String.t()) :: :ok | {:error, any()}

  @doc """
  Gets a public or signed URL for a file.

  ## Parameters
  - storage_path: Path to the file in storage
  - opts: Additional options (expires_in, etc.)

  ## Returns
  - {:ok, url}
  - {:error, reason}
  """
  @callback get_url(storage_path :: String.t(), opts :: keyword()) ::
              {:ok, String.t()} | {:error, any()}

  @doc """
  Gets the appropriate storage adapter based on configuration.
  """
  def get_adapter do
    case Application.get_env(:assetronics, :storage_provider, :local) do
      :s3 -> Assetronics.Files.Storage.S3Adapter
      :local -> Assetronics.Files.Storage.LocalAdapter
      _ -> Assetronics.Files.Storage.LocalAdapter
    end
  end

  @doc """
  Dispatches upload to the configured adapter.
  """
  def upload(file_path, destination, opts \\ []) do
    adapter = get_adapter()
    adapter.upload(file_path, destination, opts)
  end

  @doc """
  Dispatches delete to the configured adapter.
  """
  def delete(storage_path) do
    adapter = get_adapter()
    adapter.delete(storage_path)
  end

  @doc """
  Dispatches get_url to the configured adapter.
  """
  def get_url(storage_path, opts \\ []) do
    adapter = get_adapter()
    adapter.get_url(storage_path, opts)
  end

  @doc """
  Generates a unique filename for storage.
  """
  def generate_filename(original_filename) do
    ext = Path.extname(original_filename)
    base = Path.basename(original_filename, ext)
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    random = :crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)

    # Sanitize base filename
    sanitized_base =
      base
      |> String.replace(~r/[^a-zA-Z0-9_-]/, "_")
      |> String.slice(0..50)

    "#{sanitized_base}_#{timestamp}_#{random}#{ext}"
  end

  @doc """
  Builds a storage path based on category and tenant.
  """
  def build_storage_path(tenant, category, filename) do
    Path.join([tenant, category, filename])
  end
end
