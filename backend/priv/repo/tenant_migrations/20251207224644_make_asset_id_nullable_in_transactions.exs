defmodule Assetronics.Repo.Migrations.MakeAssetIdNullableInTransactions do
  use Ecto.Migration

  def up do
    # Drop the NOT NULL constraint on asset_id
    execute "ALTER TABLE transactions ALTER COLUMN asset_id DROP NOT NULL"
  end

  def down do
    # Re-add the NOT NULL constraint (but only if there are no NULL values)
    execute "ALTER TABLE transactions ALTER COLUMN asset_id SET NOT NULL"
  end
end
