defmodule Assetronics.Repo.Migrations.AddAgentFieldsToAssets do
  use Ecto.Migration

  def change do
    alter table(:assets) do
      add :hostname, :string
      add :os_info, :string
      add :last_checkin_at, :naive_datetime
    end
  end
end
