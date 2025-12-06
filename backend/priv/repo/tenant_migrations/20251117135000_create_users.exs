defmodule Assetronics.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :first_name, :string
      add :last_name, :string
      add :role, :string, null: false, default: "employee"
      add :status, :string, null: false, default: "active"

      # Profile fields
      add :phone, :string
      add :avatar_url, :string
      add :timezone, :string, default: "UTC"
      add :locale, :string, default: "en"

      # Security fields
      add :email_verified_at, :naive_datetime
      add :last_login_at, :naive_datetime
      add :last_login_ip, :string
      add :failed_login_attempts, :integer, default: 0
      add :locked_at, :naive_datetime

      # Password reset
      add :password_reset_token, :string
      add :password_reset_sent_at, :naive_datetime

      # Email verification
      add :email_verification_token, :string
      add :email_verification_sent_at, :naive_datetime

      # Relations
      add :employee_id, references(:employees, type: :binary_id, on_delete: :nilify_all)

      # Metadata
      add :metadata, :map

      timestamps()
    end

    create unique_index(:users, [:email])
    create index(:users, [:role])
    create index(:users, [:status])
    create index(:users, [:employee_id])
    create index(:users, [:password_reset_token])
    create index(:users, [:email_verification_token])
  end
end
