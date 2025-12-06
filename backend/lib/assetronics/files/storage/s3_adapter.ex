defmodule Assetronics.Files.Storage.S3Adapter do
  @moduledoc """
  AWS S3 storage adapter for file uploads.

  Configuration (config/runtime.exs):
  ```
  config :assetronics,
    storage_provider: :s3,
    s3_bucket: System.get_env("AWS_S3_BUCKET"),
    s3_region: System.get_env("AWS_REGION") || "us-east-1"

  config :ex_aws,
    access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
    secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
    region: System.get_env("AWS_REGION") || "us-east-1"
  ```
  """

  @behaviour Assetronics.Files.Storage.Adapter

  require Logger

  @impl true
  def upload(file_path, destination, opts \\ []) do
    bucket = get_bucket()
    region = get_region()
    content_type = Keyword.get(opts, :content_type, "application/octet-stream")
    metadata = Keyword.get(opts, :metadata, %{})
    acl = Keyword.get(opts, :acl, :private)

    # Read file content
    case File.read(file_path) do
      {:ok, file_content} ->
        # Upload to S3
        s3_opts = [
          content_type: content_type,
          acl: acl,
          metadata: metadata
        ]

        case ExAws.S3.put_object(bucket, destination, file_content, s3_opts)
             |> ExAws.request() do
          {:ok, _response} ->
            {:ok,
             %{
               storage_provider: "s3",
               storage_path: destination,
               s3_bucket: bucket,
               s3_key: destination,
               s3_region: region
             }}

          {:error, reason} ->
            Logger.error("Failed to upload file to S3: #{inspect(reason)}")
            {:error, :upload_failed}
        end

      {:error, reason} ->
        Logger.error("Failed to read file for S3 upload: #{inspect(reason)}")
        {:error, :file_read_failed}
    end
  end

  @impl true
  def delete(storage_path) do
    bucket = get_bucket()

    case ExAws.S3.delete_object(bucket, storage_path) |> ExAws.request() do
      {:ok, _response} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to delete file from S3: #{inspect(reason)}")
        {:error, :delete_failed}
    end
  end

  @impl true
  def get_url(storage_path, opts \\ []) do
    bucket = get_bucket()
    region = get_region()
    expires_in = Keyword.get(opts, :expires_in, 3600)
    public = Keyword.get(opts, :public, false)

    if public do
      # Return public URL
      url = "https://#{bucket}.s3.#{region}.amazonaws.com/#{storage_path}"
      {:ok, url}
    else
      # Generate presigned URL
      config = ExAws.Config.new(:s3, region: region)

      case ExAws.S3.presigned_url(config, :get, bucket, storage_path, expires_in: expires_in) do
        {:ok, url} -> {:ok, url}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  # Private functions

  defp get_bucket do
    Application.get_env(:assetronics, :s3_bucket) ||
      raise "S3 bucket not configured. Set AWS_S3_BUCKET environment variable."
  end

  defp get_region do
    Application.get_env(:assetronics, :s3_region, "us-east-1")
  end
end
