defmodule Assetronics.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :type, :string
      add :description, :text
      add :parent_id, references(:organizations, type: :binary_id, on_delete: :nilify_all)

      timestamps()
    end

    create index(:organizations, [:parent_id])
    create index(:organizations, [:type])
  end
end
