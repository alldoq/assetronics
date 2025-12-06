defmodule Assetronics.Repo.Migrations.CreateWorkflows do
  use Ecto.Migration

  def change do
    create table(:workflows, primary_key: false) do
      add :id, :binary_id, primary_key: true
      
      add :workflow_type, :string, null: false  # onboarding, offboarding, repair, procurement, transfer
      add :status, :string, default: "pending", null: false  # pending, in_progress, completed, cancelled, failed
      add :priority, :string, default: "normal"  # low, normal, high, urgent
      
      # Related entities
      add :asset_id, references(:assets, type: :binary_id, on_delete: :nilify_all)
      add :employee_id, references(:employees, type: :binary_id, on_delete: :nilify_all)
      
      # Workflow details
      add :title, :string, null: false
      add :description, :text
      add :steps, {:array, :map}, default: []  # Array of workflow steps with completion status
      add :current_step, :integer, default: 0
      
      # Assignment and approval
      add :assigned_to, :string  # User ID or team name
      add :approver, :string
      add :approved_at, :naive_datetime
      add :approval_notes, :text
      
      # Dates
      add :due_date, :date
      add :started_at, :naive_datetime
      add :completed_at, :naive_datetime
      add :cancelled_at, :naive_datetime
      
      # Integration tracking
      add :triggered_by, :string  # manual, hris_sync, scheduled, api
      add :integration_id, references(:integrations, type: :binary_id, on_delete: :nilify_all)
      
      # Metadata
      add :metadata, :map, default: %{}
      add :notes, :text
      
      timestamps()
    end

    create index(:workflows, [:workflow_type])
    create index(:workflows, [:status])
    create index(:workflows, [:employee_id])
    create index(:workflows, [:asset_id])
    create index(:workflows, [:due_date])
  end
end
