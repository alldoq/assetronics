defmodule Assetronics.Repo.Migrations.AddEmployeeAndWorkflowToFiles do
  use Ecto.Migration

  def change do
    alter table(:files) do
      add :employee_id, references(:employees, type: :binary_id, on_delete: :delete_all)
      add :workflow_id, references(:workflows, type: :binary_id, on_delete: :delete_all)
    end

    create index(:files, [:employee_id])
    create index(:files, [:workflow_id])
  end
end
