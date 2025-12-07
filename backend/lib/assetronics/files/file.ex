defmodule Assetronics.Files.File do
  @moduledoc """
  File schema for storing uploaded files.

  Supports multiple file types:
  - Images (avatar, asset photos)
  - Documents (PDFs, spreadsheets)
  - Attachments for workflows

  Files can be stored in:
  - S3 (production)
  - Local filesystem (development)
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Assetronics.Accounts.User
  alias Assetronics.Assets.Asset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  # Allowed file categories
  @categories ~w(avatar asset_photo document attachment other)

  # Max file sizes (in bytes)
  @max_file_sizes %{
    "avatar" => 5_000_000,      # 5 MB
    "asset_photo" => 10_000_000, # 10 MB
    "document" => 50_000_000,    # 50 MB
    "attachment" => 50_000_000,  # 50 MB
    "other" => 25_000_000        # 25 MB
  }

  # Allowed MIME types per category
  @allowed_mime_types %{
    "avatar" => ["image/jpeg", "image/png", "image/webp", "image/gif"],
    "asset_photo" => ["image/jpeg", "image/png", "image/webp"],
    "document" => [
      "application/pdf",
      "application/vnd.ms-excel",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "application/vnd.ms-powerpoint",
      "application/vnd.openxmlformats-officedocument.presentationml.presentation",
      "application/msword",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "text/csv"
    ],
    "attachment" => ["*"],  # Allow all types
    "other" => ["*"]
  }

  schema "files" do
    field :filename, :string
    field :original_filename, :string
    field :content_type, :string
    field :file_size, :integer
    field :category, :string, default: "other"

    # Storage location
    field :storage_path, :string
    field :storage_provider, :string, default: "local"  # local, s3

    # S3-specific fields
    field :s3_bucket, :string
    field :s3_key, :string
    field :s3_region, :string

    # Image-specific fields
    field :width, :integer
    field :height, :integer

    # Metadata
    field :metadata, :map

    # Associations
    belongs_to :uploaded_by, User
    belongs_to :asset, Asset
    belongs_to :employee, Assetronics.Employees.Employee
    belongs_to :workflow, Assetronics.Workflows.Workflow
    # TODO: Uncomment when WorkflowExecution schema is created
    # belongs_to :workflow_execution, WorkflowExecution

    # Polymorphic association - for flexible attachment to any resource
    field :attachable_type, :string
    field :attachable_id, :binary_id

    timestamps()
  end

  @doc """
  Changeset for creating a file record.
  """
  def changeset(file, attrs) do
    file
    |> cast(attrs, [
      :filename,
      :original_filename,
      :content_type,
      :file_size,
      :category,
      :storage_path,
      :storage_provider,
      :s3_bucket,
      :s3_key,
      :s3_region,
      :width,
      :height,
      :metadata,
      :uploaded_by_id,
      :asset_id,
      :employee_id,
      :workflow_id,
      # :workflow_execution_id,  # TODO: Uncomment when WorkflowExecution exists
      :attachable_type,
      :attachable_id
    ])
    |> validate_required([
      :filename,
      :original_filename,
      :content_type,
      :file_size,
      :category,
      :storage_provider
    ])
    |> validate_inclusion(:category, @categories)
    |> validate_inclusion(:storage_provider, ["local", "s3"])
    |> validate_file_size()
    |> validate_content_type()
  end

  @doc """
  Returns the maximum file size for a given category.
  """
  def max_file_size(category) do
    Map.get(@max_file_sizes, category, @max_file_sizes["other"])
  end

  @doc """
  Returns allowed MIME types for a given category.
  """
  def allowed_mime_types(category) do
    Map.get(@allowed_mime_types, category, @allowed_mime_types["other"])
  end

  @doc """
  Returns all allowed categories.
  """
  def categories, do: @categories

  @doc """
  Checks if a file is an image.
  """
  def image?(%__MODULE__{content_type: content_type}) do
    String.starts_with?(content_type, "image/")
  end

  @doc """
  Checks if a file is a document.
  """
  def document?(%__MODULE__{category: category}) do
    category == "document"
  end

  # Private validation functions

  defp validate_file_size(changeset) do
    category = get_field(changeset, :category)
    file_size = get_field(changeset, :file_size)

    if file_size && category do
      max_size = max_file_size(category)

      if file_size > max_size do
        add_error(
          changeset,
          :file_size,
          "file size must be less than #{format_bytes(max_size)}"
        )
      else
        changeset
      end
    else
      changeset
    end
  end

  defp validate_content_type(changeset) do
    category = get_field(changeset, :category)
    content_type = get_field(changeset, :content_type)

    if content_type && category do
      allowed = allowed_mime_types(category)

      if "*" in allowed || content_type in allowed do
        changeset
      else
        add_error(
          changeset,
          :content_type,
          "content type #{content_type} is not allowed for #{category}"
        )
      end
    else
      changeset
    end
  end

  defp format_bytes(bytes) do
    cond do
      bytes >= 1_000_000_000 -> "#{Float.round(bytes / 1_000_000_000, 2)} GB"
      bytes >= 1_000_000 -> "#{Float.round(bytes / 1_000_000, 2)} MB"
      bytes >= 1_000 -> "#{Float.round(bytes / 1_000, 2)} KB"
      true -> "#{bytes} bytes"
    end
  end
end
