defmodule Assetronics.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string, null: false
      add :original_filename, :string, null: false
      add :content_type, :string, null: false
      add :file_size, :bigint, null: false
      add :category, :string, null: false, default: "other"

      # Storage location
      add :storage_path, :string
      add :storage_provider, :string, null: false, default: "local"

      # S3-specific fields
      add :s3_bucket, :string
      add :s3_key, :string
      add :s3_region, :string

      # Image-specific fields
      add :width, :integer
      add :height, :integer

      # Metadata
      add :metadata, :map

      # Associations
      add :uploaded_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :asset_id, references(:assets, type: :binary_id, on_delete: :delete_all)
      # TODO: Uncomment when WorkflowExecution table is created
      # add :workflow_execution_id, references(:workflow_executions, type: :binary_id, on_delete: :delete_all)

      # Polymorphic association
      add :attachable_type, :string
      add :attachable_id, :binary_id

      timestamps()
    end

    create index(:files, [:category])
    create index(:files, [:uploaded_by_id])
    create index(:files, [:asset_id])
    # TODO: Uncomment when WorkflowExecution table is created
    # create index(:files, [:workflow_execution_id])
    create index(:files, [:attachable_type, :attachable_id])
    create index(:files, [:storage_provider])
  end
end
