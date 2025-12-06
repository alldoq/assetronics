defmodule Assetronics.Repo.Migrations.AddIsPrimaryToIntegrations do
  use Ecto.Migration

  def change do
    # Add is_primary column
    alter table(:integrations) do
      add :is_primary, :boolean, default: false, null: false
    end

    # Add partial unique index to ensure only one primary per integration_type
    # This allows multiple integrations of the same type, but only one can be primary
    create unique_index(
      :integrations,
      [:integration_type],
      where: "is_primary = true",
      name: :idx_integrations_primary_per_type
    )

    # Add regular index for querying primary integrations
    create index(:integrations, [:is_primary])
  end
end
