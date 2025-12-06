defmodule Assetronics.Repo.Migrations.CreateDepartments do
  use Ecto.Migration

  def change do
    create table(:departments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :string
      add :code, :string

      timestamps()
    end

    create unique_index(:departments, [:name])
    create unique_index(:departments, [:code])
  end
end
