defmodule Assetronics.Repo.Migrations.CreateAssets do
  use Ecto.Migration

  def change do
    create table(:assets, primary_key: false) do
      add :id, :binary_id, primary_key: true

      # Basic identification
      add :asset_tag, :string, null: false
      add :name, :string, null: false
      add :description, :text

      # Hardware details
      add :category, :string, null: false  # laptop, desktop, monitor, phone, tablet, peripheral, other
      add :type, :string  # MacBook Pro, iPhone, Dell Monitor, etc.
      add :make, :string  # Apple, Dell, Lenovo, etc.
      add :model, :string
      add :serial_number_encrypted, :binary  # Encrypted with Cloak
      add :serial_number_hash, :binary  # For searching without decrypting

      # Purchase & warranty (encrypted for security)
      add :purchase_date, :date
      add :purchase_cost_encrypted, :binary  # Encrypted
      add :purchase_cost_hash, :binary  # For aggregations
      add :vendor, :string
      add :po_number_encrypted, :binary  # Encrypted
      add :invoice_number_encrypted, :binary  # Encrypted

      add :warranty_start_date, :date
      add :warranty_end_date, :date
      add :warranty_provider, :string
      add :warranty_info_encrypted, :binary  # Encrypted warranty details

      # Status and lifecycle
      add :status, :string, default: "in_stock", null: false
      # Statuses: in_stock, assigned, in_transit, in_repair, retired, lost, stolen
      add :condition, :string  # new, good, fair, poor, damaged
      add :location_id, references(:locations, type: :binary_id, on_delete: :nilify_all)
      add :employee_id, references(:employees, type: :binary_id, on_delete: :nilify_all)

      # Assignment tracking
      add :assigned_at, :naive_datetime
      add :assignment_type, :string  # permanent, temporary, loaner
      add :expected_return_date, :date

      # Financial tracking
      add :depreciation_method, :string  # straight_line, declining_balance
      add :useful_life_months, :integer
      add :salvage_value_encrypted, :binary  # Encrypted
      add :current_book_value_encrypted, :binary  # Encrypted
      add :cost_center, :string
      add :department, :string

      # Metadata
      add :notes, :text
      add :tags, {:array, :string}, default: []
      add :custom_fields, :map, default: %{}

      # Audit trail
      add :retired_at, :naive_datetime
      add :retired_reason, :string
      add :last_audit_date, :date
      add :next_audit_date, :date

      timestamps()
    end

    create unique_index(:assets, [:asset_tag])
    create index(:assets, [:serial_number_hash])
    create index(:assets, [:status])
    create index(:assets, [:category])
    create index(:assets, [:employee_id])
    create index(:assets, [:location_id])
    create index(:assets, [:warranty_end_date])
    create index(:assets, [:tags], using: :gin)
  end
end
