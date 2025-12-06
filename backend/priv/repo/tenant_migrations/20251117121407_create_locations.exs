defmodule Assetronics.Repo.Migrations.CreateLocations do
  use Ecto.Migration

  def change do
    create table(:locations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      
      add :name, :string, null: false
      add :location_type, :string, null: false  # office, warehouse, employee_home, remote, other
      add :address_line1_encrypted, :binary  # Encrypted
      add :address_line2_encrypted, :binary
      add :city, :string
      add :state_province, :string
      add :postal_code_encrypted, :binary  # Encrypted
      add :country, :string
      
      # Contact information
      add :contact_name, :string
      add :contact_email, :string
      add :contact_phone_encrypted, :binary  # Encrypted
      
      # Metadata
      add :notes, :text
      add :is_active, :boolean, default: true
      add :custom_fields, :map, default: %{}
      
      timestamps()
    end

    create index(:locations, [:location_type])
    create index(:locations, [:is_active])
  end
end
