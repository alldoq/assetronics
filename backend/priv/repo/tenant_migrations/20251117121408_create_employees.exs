defmodule Assetronics.Repo.Migrations.CreateEmployees do
  use Ecto.Migration

  def change do
    create table(:employees, primary_key: false) do
      add :id, :binary_id, primary_key: true
      
      # Basic information
      add :employee_id, :string  # Company employee ID
      add :hris_id, :string  # ID from HRIS system
      add :first_name_encrypted, :binary  # Encrypted
      add :last_name_encrypted, :binary  # Encrypted
      add :email, :string, null: false
      add :phone_encrypted, :binary  # Encrypted
      
      # Employment details
      add :job_title, :string
      add :department, :string
      add :manager_id, references(:employees, type: :binary_id, on_delete: :nilify_all)
      add :hire_date, :date
      add :termination_date, :date
      add :employment_status, :string, default: "active"  # active, on_leave, terminated
      
      # Location
      add :office_location_id, references(:locations, type: :binary_id, on_delete: :nilify_all)
      add :work_location_type, :string  # office, remote, hybrid
      add :home_address_encrypted, :binary  # Encrypted JSON
      
      # Personal information (encrypted for privacy)
      add :date_of_birth_encrypted, :binary  # Encrypted
      add :ssn_encrypted, :binary  # Encrypted (for countries that use SSN)
      add :national_id_encrypted, :binary  # Encrypted
      
      # Integration sync
      add :last_synced_at, :naive_datetime
      add :sync_source, :string  # bamboohr, workday, rippling, etc.
      add :external_data, :map, default: %{}  # Additional HRIS data
      
      # Metadata
      add :notes, :text
      add :custom_fields, :map, default: %{}
      
      timestamps()
    end

    create unique_index(:employees, [:email])
    create unique_index(:employees, [:employee_id])
    create index(:employees, [:hris_id])
    create index(:employees, [:employment_status])
    create index(:employees, [:department])
    create index(:employees, [:manager_id])
  end
end
