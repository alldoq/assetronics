defmodule Assetronics.Repo.Migrations.AddHierarchyToDepartments do
  use Ecto.Migration

  def change do
    alter table(:departments) do
      add :type, :string
      add :parent_id, references(:departments, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:departments, [:parent_id])
    create index(:departments, [:type])
  end
end
