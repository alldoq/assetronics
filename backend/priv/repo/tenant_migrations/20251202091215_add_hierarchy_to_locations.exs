defmodule Assetronics.Repo.Migrations.AddHierarchyToLocations do
  use Ecto.Migration

  def change do
    alter table(:locations) do
      add :parent_id, references(:locations, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:locations, [:parent_id])
  end
end
