defmodule Assetronics.Repo.Migrations.CreateSoftwareAssignments do
  use Ecto.Migration

  def change do
    create table(:software_assignments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :employee_id, references(:employees, type: :binary_id, on_delete: :delete_all)
      add :software_license_id, references(:software_licenses, type: :binary_id, on_delete: :delete_all)
      
      add :assigned_at, :date
      add :last_used_at, :naive_datetime
      add :status, :string, default: "active" # active, reclaimed

      timestamps()
    end

    create index(:software_assignments, [:employee_id])
    create index(:software_assignments, [:software_license_id])
    create unique_index(:software_assignments, [:employee_id, :software_license_id])
  end
end