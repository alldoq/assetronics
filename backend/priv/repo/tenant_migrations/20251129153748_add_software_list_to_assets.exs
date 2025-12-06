defmodule Assetronics.Repo.Migrations.AddSoftwareListToAssets do
  use Ecto.Migration

  def change do
    alter table(:assets) do
      add :installed_software, :map, default: fragment("'[]'::jsonb")
    end
  end
end
