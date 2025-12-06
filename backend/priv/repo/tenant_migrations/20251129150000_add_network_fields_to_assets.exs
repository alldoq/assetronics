defmodule Assetronics.Repo.Migrations.AddNetworkFieldsToAssets do
  use Ecto.Migration

  def change do
    alter table(:assets) do
      add :ip_address, :string
      add :mac_address, :string
    end
  end
end
