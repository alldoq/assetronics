defmodule Assetronics.Repo.Migrations.AddLastLoginToEmployees do
  use Ecto.Migration

  def change do
    alter table(:employees) do
      add :last_login_at, :naive_datetime
    end
  end
end