defmodule Assetronics.Notifications.InAppNotification do
  @moduledoc """
  Schema for in-app notifications stored in the database.
  These are displayed in the user's notification center and broadcast via Phoenix Channels.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Assetronics.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "in_app_notifications" do
    belongs_to :user, User
    field :notification_type, :string
    field :title, :string
    field :body, :string
    field :action_url, :string
    field :action_text, :string
    field :read, :boolean, default: false
    field :read_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:user_id, :notification_type, :title, :body, :action_url, :action_text, :read, :read_at])
    |> validate_required([:user_id, :notification_type, :title, :body])
    |> foreign_key_constraint(:user_id)
  end

  @doc false
  def mark_as_read_changeset(notification) do
    notification
    |> change(%{read: true, read_at: DateTime.utc_now()})
  end
end
