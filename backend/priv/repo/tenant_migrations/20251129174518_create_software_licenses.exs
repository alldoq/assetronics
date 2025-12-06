defmodule Assetronics.Repo.Migrations.CreateSoftwareLicenses do
  use Ecto.Migration

  def change do
    create table(:software_licenses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :vendor, :string, null: false
      add :description, :text
      
      # Financials
      add :total_seats, :integer, default: 0
      add :annual_cost_encrypted, :binary
      add :cost_per_seat_encrypted, :binary
      
      # Dates
      add :purchase_date, :date
      add :expiration_date, :date
      
      # Status
      add :status, :string, default: "active"
      add :license_key_encrypted, :binary
      
      # Integration Mapping (for automated reclamation)
      add :integration_id, references(:integrations, type: :binary_id, on_delete: :nilify_all)
      add :sso_app_id, :string

      timestamps()
    end

    create index(:software_licenses, [:integration_id])
    create index(:software_licenses, [:vendor])
    create unique_index(:software_licenses, [:name, :vendor])
  end
end