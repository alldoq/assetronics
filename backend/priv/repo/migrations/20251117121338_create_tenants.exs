defmodule Assetronics.Repo.Migrations.CreateTenants do
  use Ecto.Migration

  def change do
    create table(:tenants, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :status, :string, default: "active", null: false
      add :plan, :string, default: "starter", null: false

      # Company information
      add :company_name, :string
      add :industry, :string
      add :employee_count_range, :string
      add :website, :string

      # Contact information
      add :primary_contact_name, :string
      add :primary_contact_email, :string
      add :primary_contact_phone, :string

      # Billing information
      add :billing_email, :string
      add :billing_address, :text

      # Settings
      add :settings, :map, default: %{}
      add :features, {:array, :string}, default: []

      # Subscription
      add :trial_ends_at, :naive_datetime
      add :subscription_starts_at, :naive_datetime
      add :subscription_ends_at, :naive_datetime

      timestamps()
    end

    create unique_index(:tenants, [:slug])
    create index(:tenants, [:status])
  end
end
