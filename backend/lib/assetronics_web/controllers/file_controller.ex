defmodule AssetronicsWeb.FileController do
  @moduledoc """
  Handles file uploads and management.

  Endpoints:
  - POST /files - Upload a file
  - GET /files - List all files
  - GET /files/:id - Get file details
  - DELETE /files/:id - Delete a file
  - POST /users/:id/avatar - Upload user avatar
  - POST /assets/:id/photos - Upload asset photo
  - POST /workflows/:id/attachments - Upload workflow attachment
  """

  use AssetronicsWeb, :controller

  alias Assetronics.Files

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  Lists all files for the current tenant.
  """
  def index(conn, params) do
    tenant = conn.assigns[:tenant]

    opts = build_filter_opts(params)
    files = Files.list_files(tenant, opts)

    # Enrich files with URLs
    files_with_urls =
      Enum.map(files, fn file ->
        {:ok, url} = Files.get_file_url(file)
        Map.put(file, :url, url)
      end)

    conn
    |> put_status(:ok)
    |> render(:index, files: files_with_urls)
  end

  @doc """
  Gets a single file.
  """
  def show(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]

    case Files.get_file(tenant, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(:error, message: "File not found")

      file ->
        {:ok, url} = Files.get_file_url(file)
        file_with_url = Map.put(file, :url, url)

        conn
        |> put_status(:ok)
        |> render(:show, file: file_with_url)
    end
  end

  @doc """
  Uploads a file.

  Expects multipart/form-data with:
  - file: The file to upload
  - category: File category (optional, default: "other")
  - attachable_type: Resource type (optional)
  - attachable_id: Resource ID (optional)
  """
  def create(conn, %{"file" => upload} = params) do
    tenant = conn.assigns[:tenant]
    current_user = conn.assigns[:current_user]

    attrs =
      params
      |> Map.take(["category", "attachable_type", "attachable_id", "metadata"])
      |> Map.put("uploaded_by_id", current_user.id)
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)

    case Files.upload_file(tenant, upload, attrs) do
      {:ok, file} ->
        {:ok, url} = Files.get_file_url(file)
        file_with_url = Map.put(file, :url, url)

        conn
        |> put_status(:created)
        |> render(:show, file: file_with_url)

      {:error, :file_too_large} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, message: "File is too large")

      {:error, :invalid_file_type} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, message: "Invalid file type")

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, changeset: changeset)

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> render(:error, message: "Failed to upload file: #{inspect(reason)}")
    end
  end

  @doc """
  Deletes a file.
  """
  def delete(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]

    case Files.get_file(tenant, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(:error, message: "File not found")

      file ->
        case Files.delete_file(tenant, file) do
          {:ok, _file} ->
            conn
            |> send_resp(:no_content, "")

          {:error, reason} ->
            conn
            |> put_status(:internal_server_error)
            |> render(:error, message: "Failed to delete file: #{inspect(reason)}")
        end
    end
  end

  @doc """
  Uploads an avatar for a user.
  """
  def upload_avatar(conn, %{"user_id" => user_id, "file" => upload}) do
    tenant = conn.assigns[:tenant]
    current_user = conn.assigns[:current_user]

    # Check if user is uploading their own avatar or is an admin
    unless current_user.id == user_id || current_user.role in ["super_admin", "admin"] do
      conn
      |> put_status(:forbidden)
      |> render(:error, message: "You can only upload your own avatar")
    else
      case Files.upload_avatar(tenant, user_id, upload) do
        {:ok, file} ->
          {:ok, url} = Files.get_file_url(file)
          file_with_url = Map.put(file, :url, url)

          conn
          |> put_status(:created)
          |> render(:show, file: file_with_url)

        {:error, :file_too_large} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(:error, message: "Avatar file is too large (max 5MB)")

        {:error, :invalid_file_type} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(:error, message: "Invalid file type. Allowed: JPEG, PNG, WebP, GIF")

        {:error, reason} ->
          conn
          |> put_status(:internal_server_error)
          |> render(:error, message: "Failed to upload avatar: #{inspect(reason)}")
      end
    end
  end

  @doc """
  Uploads a photo for an asset.
  """
  def upload_asset_photo(conn, %{"asset_id" => asset_id, "file" => upload}) do
    tenant = conn.assigns[:tenant]
    current_user = conn.assigns[:current_user]

    # Check if user has permission (managers and admins)
    unless current_user.role in ["super_admin", "admin", "manager"] do
      conn
      |> put_status(:forbidden)
      |> render(:error, message: "You don't have permission to upload asset photos")
    else
      case Files.upload_asset_photo(tenant, asset_id, upload, current_user.id) do
        {:ok, file} ->
          {:ok, url} = Files.get_file_url(file)
          file_with_url = Map.put(file, :url, url)

          conn
          |> put_status(:created)
          |> render(:show, file: file_with_url)

        {:error, :file_too_large} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(:error, message: "Photo file is too large (max 10MB)")

        {:error, :invalid_file_type} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(:error, message: "Invalid file type. Allowed: JPEG, PNG, WebP")

        {:error, reason} ->
          conn
          |> put_status(:internal_server_error)
          |> render(:error, message: "Failed to upload photo: #{inspect(reason)}")
      end
    end
  end

  @doc """
  Uploads an attachment for a workflow execution.
  """
  def upload_workflow_attachment(conn, %{"workflow_id" => workflow_id, "file" => upload}) do
    tenant = conn.assigns[:tenant]
    current_user = conn.assigns[:current_user]

    case Files.upload_workflow_attachment(tenant, workflow_id, upload, current_user.id) do
      {:ok, file} ->
        {:ok, url} = Files.get_file_url(file)
        file_with_url = Map.put(file, :url, url)

        conn
        |> put_status(:created)
        |> render(:show, file: file_with_url)

      {:error, :file_too_large} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, message: "Attachment file is too large (max 50MB)")

      {:error, :invalid_file_type} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, message: "Invalid file type")

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> render(:error, message: "Failed to upload attachment: #{inspect(reason)}")
    end
  end

  # Private functions

  defp build_filter_opts(params) do
    []
    |> maybe_add_filter(:category, params["category"])
    |> maybe_add_filter(:attachable_type, params["attachable_type"])
    |> maybe_add_filter(:attachable_id, params["attachable_id"])
    |> maybe_add_filter(:uploaded_by_id, params["uploaded_by_id"])
  end

  defp maybe_add_filter(opts, _key, nil), do: opts
  defp maybe_add_filter(opts, key, value), do: [{key, value} | opts]
end
