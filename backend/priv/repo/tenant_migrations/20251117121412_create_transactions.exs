defmodule Assetronics.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      
      add :transaction_type, :string, null: false
      # Types: assignment, return, transfer, repair_start, repair_complete, 
      # purchase, retire, lost, stolen, audit, status_change, location_change
      
      add :asset_id, references(:assets, type: :binary_id, on_delete: :nilify_all), null: false
      add :employee_id, references(:employees, type: :binary_id, on_delete: :nilify_all)
      add :workflow_id, references(:workflows, type: :binary_id, on_delete: :nilify_all)
      
      # Transaction details
      add :from_status, :string
      add :to_status, :string
      add :from_location_id, references(:locations, type: :binary_id, on_delete: :nilify_all)
      add :to_location_id, references(:locations, type: :binary_id, on_delete: :nilify_all)
      add :from_employee_id, references(:employees, type: :binary_id, on_delete: :nilify_all)
      add :to_employee_id, references(:employees, type: :binary_id, on_delete: :nilify_all)
      
      # Metadata
      add :description, :text
      add :notes, :text
      add :performed_by, :string  # User who performed the transaction
      add :performed_at, :naive_datetime, null: false
      
      # Financial data (encrypted)
      add :transaction_amount_encrypted, :binary  # For repairs, purchases, etc.
      add :transaction_amount_hash, :binary
      
      # Audit trail
      add :metadata, :map, default: %{}
      add :ip_address, :string
      add :user_agent, :string
      
      timestamps()
    end

    create index(:transactions, [:asset_id])
    create index(:transactions, [:employee_id])
    create index(:transactions, [:transaction_type])
    create index(:transactions, [:performed_at])
    create index(:transactions, [:workflow_id])
  end
end
