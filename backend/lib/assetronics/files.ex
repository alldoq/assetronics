defmodule Assetronics.Files do
  @moduledoc """
  The Files context.

  Handles file uploads, storage, and retrieval for:
  - User avatars
  - Asset photos
  - Workflow attachments
  - General documents
  """

  import Ecto.Query, warn: false
  alias Assetronics.Repo
  alias Assetronics.Files.File
  alias Assetronics.Files.Storage.Adapter
  alias Triplex

  @doc """
  Lists all files for a tenant.

  ## Options
  - category: Filter by category
  - attachable_type: Filter by attachable type
  - attachable_id: Filter by attachable ID
  """
  def list_files(tenant, opts \\ []) do
    query = from(f in File, order_by: [desc: f.inserted_at])

    query
    |> apply_filters(opts)
    |> then(&Repo.all(&1, prefix: Triplex.to_prefix(tenant)))
  end

  @doc """
  Gets a single file.
  """
  def get_file!(tenant, id), do: Repo.get!(File, id, prefix: Triplex.to_prefix(tenant))

  @doc """
  Gets a file by ID (returns nil if not found).
  """
  def get_file(tenant, id) do
    query = from(f in File, where: f.id == ^id)
    Repo.one(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Uploads a file.

  ## Parameters
  - tenant: Tenant slug
  - upload: Plug.Upload struct or file path
  - attrs: Additional attributes (category, uploaded_by_id, etc.)

  ## Returns
  - {:ok, file}
  - {:error, changeset}
  """
  def upload_file(tenant, upload, attrs \\ %{}) do
    with {:ok, validated_attrs} <- validate_upload(upload, attrs),
         {:ok, storage_info} <- store_file(tenant, upload, validated_attrs),
         {:ok, file} <- create_file_record(tenant, storage_info, validated_attrs) do
      {:ok, file}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Deletes a file and removes it from storage.
  """
  def delete_file(tenant, %File{} = file) do
    # Delete from storage
    case Adapter.delete(file.storage_path) do
      :ok ->
        Repo.delete(tenant, prefix: Triplex.to_prefix(file))

      {:error, reason} ->
        # Still delete the database record even if storage deletion fails
        Repo.delete(tenant, prefix: Triplex.to_prefix(file))
        {:error, reason}
    end
  end

  @doc """
  Gets a URL for accessing a file.

  ## Options
  - expires_in: Expiration time in seconds (for signed URLs)
  - public: Whether to generate a public URL
  """
  def get_file_url(%File{} = file, opts \\ []) do
    Adapter.get_url(file.storage_path, opts)
  end

  @doc """
  Gets files attached to a specific resource.
  """
  def get_attachments(tenant, attachable_type, attachable_id) do
    query =
      from f in File,
        where: f.attachable_type == ^attachable_type and f.attachable_id == ^attachable_id,
        order_by: [desc: f.inserted_at]

    Repo.all(tenant, prefix: Triplex.to_prefix(query))
  end

  @doc """
  Uploads an avatar for a user.
  """
  def upload_avatar(tenant, user_id, upload) do
    # Delete old avatar if exists
    delete_user_avatar(tenant, user_id)

    # Upload new avatar
    upload_file(tenant, upload, %{
      category: "avatar",
      uploaded_by_id: user_id,
      attachable_type: "User",
      attachable_id: user_id
    })
  end

  @doc """
  Uploads a photo for an asset.
  """
  def upload_asset_photo(tenant, asset_id, upload, uploaded_by_id) do
    upload_file(tenant, upload, %{
      category: "asset_photo",
      uploaded_by_id: uploaded_by_id,
      asset_id: asset_id,
      attachable_type: "Asset",
      attachable_id: asset_id
    })
  end

  @doc """
  Uploads an attachment for a workflow execution.
  """
  def upload_workflow_attachment(tenant, workflow_execution_id, upload, uploaded_by_id) do
    upload_file(tenant, upload, %{
      category: "attachment",
      uploaded_by_id: uploaded_by_id,
      workflow_execution_id: workflow_execution_id,
      attachable_type: "WorkflowExecution",
      attachable_id: workflow_execution_id
    })
  end

  @doc """
  Deletes all avatars for a user.
  """
  def delete_user_avatar(tenant, user_id) do
    query =
      from f in File,
        where: f.category == "avatar" and f.attachable_id == ^user_id

    files = Repo.all(tenant, prefix: Triplex.to_prefix(query))

    Enum.each(files, fn file ->
      delete_file(tenant, file)
    end)
  end

  @doc """
  Gets the avatar for a user.
  """
  def get_user_avatar(tenant, user_id) do
    query =
      from f in File,
        where: f.category == "avatar" and f.attachable_id == ^user_id,
        order_by: [desc: f.inserted_at],
        limit: 1

    Repo.one(tenant, prefix: Triplex.to_prefix(query))
  end

  @doc """
  Gets all photos for an asset.
  """
  def get_asset_photos(tenant, asset_id) do
    query =
      from f in File,
        where: f.category == "asset_photo" and f.asset_id == ^asset_id,
        order_by: [desc: f.inserted_at]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Uploads a document for an employee (resume, ID, etc).
  """
  def upload_employee_document(tenant, employee_id, upload, uploaded_by_id, category \\ "document") do
    upload_file(tenant, upload, %{
      category: category,
      uploaded_by_id: uploaded_by_id,
      employee_id: employee_id,
      attachable_type: "Employee",
      attachable_id: employee_id
    })
  end

  @doc """
  Gets all documents for an employee.
  """
  def get_employee_documents(tenant, employee_id) do
    query =
      from f in File,
        where: f.employee_id == ^employee_id,
        order_by: [desc: f.inserted_at]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Deletes all files attached to an employee.
  """
  def delete_employee_files(tenant, employee_id) do
    query =
      from f in File,
        where: f.employee_id == ^employee_id

    files = Repo.all(query, prefix: Triplex.to_prefix(tenant))

    Enum.each(files, fn file ->
      delete_file(tenant, file)
    end)
  end

  @doc """
  Uploads an attachment for a workflow.
  """
  def upload_workflow_document(tenant, workflow_id, upload, uploaded_by_id) do
    upload_file(tenant, upload, %{
      category: "attachment",
      uploaded_by_id: uploaded_by_id,
      workflow_id: workflow_id,
      attachable_type: "Workflow",
      attachable_id: workflow_id
    })
  end

  @doc """
  Gets all attachments for a workflow.
  """
  def get_workflow_documents(tenant, workflow_id) do
    query =
      from f in File,
        where: f.workflow_id == ^workflow_id,
        order_by: [desc: f.inserted_at]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Deletes all files attached to a workflow.
  """
  def delete_workflow_files(tenant, workflow_id) do
    query =
      from f in File,
        where: f.workflow_id == ^workflow_id

    files = Repo.all(query, prefix: Triplex.to_prefix(tenant))

    Enum.each(files, fn file ->
      delete_file(tenant, file)
    end)
  end

  @doc """
  Deletes all files attached to an asset.
  """
  def delete_asset_files(tenant, asset_id) do
    query =
      from f in File,
        where: f.asset_id == ^asset_id

    files = Repo.all(query, prefix: Triplex.to_prefix(tenant))

    Enum.each(files, fn file ->
      delete_file(tenant, file)
    end)
  end

  # Private functions

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:category, category}, query ->
        from(f in query, where: f.category == ^category)

      {:attachable_type, type}, query ->
        from(f in query, where: f.attachable_type == ^type)

      {:attachable_id, id}, query ->
        from(f in query, where: f.attachable_id == ^id)

      {:uploaded_by_id, user_id}, query ->
        from(f in query, where: f.uploaded_by_id == ^user_id)

      _, query ->
        query
    end)
  end

  defp validate_upload(%Plug.Upload{} = upload, attrs) do
    category = Map.get(attrs, :category, "other")
    content_type = upload.content_type || MIME.from_path(upload.filename)

    # Check file size
    file_size = Elixir.File.stat!(upload.path).size

    if file_size > File.max_file_size(category) do
      {:error, :file_too_large}
    else
      # Check content type
      allowed_types = File.allowed_mime_types(category)

      if "*" in allowed_types || content_type in allowed_types do
        {:ok,
         Map.merge(attrs, %{
           original_filename: upload.filename,
           content_type: content_type,
           file_size: file_size
         })}
      else
        {:error, :invalid_file_type}
      end
    end
  end

  defp validate_upload(file_path, attrs) when is_binary(file_path) do
    category = Map.get(attrs, :category, "other")
    original_filename = Map.get(attrs, :original_filename, Path.basename(file_path))
    content_type = Map.get(attrs, :content_type) || MIME.from_path(original_filename)

    # Check file size
    file_size = Elixir.File.stat!(file_path).size

    if file_size > File.max_file_size(category) do
      {:error, :file_too_large}
    else
      # Check content type
      allowed_types = File.allowed_mime_types(category)

      if "*" in allowed_types || content_type in allowed_types do
        {:ok,
         Map.merge(attrs, %{
           original_filename: original_filename,
           content_type: content_type,
           file_size: file_size
         })}
      else
        {:error, :invalid_file_type}
      end
    end
  end

  defp store_file(tenant, %Plug.Upload{} = upload, attrs) do
    category = Map.get(attrs, :category, "other")
    filename = Adapter.generate_filename(attrs.original_filename)
    destination = Adapter.build_storage_path(tenant, category, filename)

    Adapter.upload(upload.path, destination,
      content_type: attrs.content_type,
      metadata: Map.get(attrs, :metadata, %{})
    )
  end

  defp store_file(tenant, file_path, attrs) when is_binary(file_path) do
    category = Map.get(attrs, :category, "other")
    filename = Adapter.generate_filename(attrs.original_filename)
    destination = Adapter.build_storage_path(tenant, category, filename)

    Adapter.upload(file_path, destination,
      content_type: attrs.content_type,
      metadata: Map.get(attrs, :metadata, %{})
    )
  end

  defp create_file_record(tenant, storage_info, attrs) do
    file_attrs =
      attrs
      |> Map.merge(storage_info)
      |> Map.put(:filename, Path.basename(storage_info.storage_path))

    %File{}
    |> File.changeset(file_attrs)
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
  end
end
