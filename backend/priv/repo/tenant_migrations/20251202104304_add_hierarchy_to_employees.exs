defmodule Assetronics.Repo.Migrations.AddHierarchyToEmployees do
  use Ecto.Migration

  def change do
    alter table(:employees) do
      add :organization_id, references(:organizations, type: :binary_id, on_delete: :nilify_all)
      add :department_id, references(:departments, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:employees, [:organization_id])
    create index(:employees, [:department_id])
  end
end
