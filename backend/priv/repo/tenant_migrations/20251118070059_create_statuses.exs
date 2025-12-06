defmodule Assetronics.Repo.Migrations.CreateStatuses do
  use Ecto.Migration

  def change do
    create table(:statuses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :value, :string, null: false
      add :description, :text
      add :color, :string, null: false, default: "primary"

      timestamps()
    end

    create unique_index(:statuses, [:value])
    create index(:statuses, [:name])
  end
end
