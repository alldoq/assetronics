defmodule Assetronics.Repo.Migrations.AddHardwareSpecsToAssets do
  use Ecto.Migration

  def change do
    alter table(:assets) do
      add :cpu_model, :string
      add :cpu_cores, :integer
      add :ram_total_gb, :integer
      add :disk_total_gb, :integer
      add :disk_free_gb, :integer
      # make and model already exist
    end
  end
end
