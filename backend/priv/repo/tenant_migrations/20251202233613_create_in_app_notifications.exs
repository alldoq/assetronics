defmodule Assetronics.Repo.Migrations.CreateInAppNotifications do
  use Ecto.Migration

  def change do
    create table(:in_app_notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :notification_type, :string, null: false
      add :title, :string, null: false
      add :body, :text, null: false
      add :action_url, :string
      add :action_text, :string
      add :read, :boolean, default: false
      add :read_at, :utc_datetime

      timestamps()
    end

    create index(:in_app_notifications, [:user_id])
    create index(:in_app_notifications, [:user_id, :read])
    create index(:in_app_notifications, [:inserted_at])
  end
end
