defmodule Assetronics.Settings.UserNotificationPreference do
  @moduledoc """
  User notification preferences for controlling which channels receive which notifications.

  Each user can customize their notification preferences per notification type:
  - asset_assigned
  - asset_returned
  - asset_due_soon
  - workflow_assigned
  - workflow_completed
  - workflow_overdue
  - integration_sync_failed
  - security_alert
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @notification_types ~w(
    asset_assigned
    asset_returned
    asset_due_soon
    workflow_assigned
    workflow_completed
    workflow_overdue
    integration_sync_failed
    security_alert
    system_announcement
  )

  @frequency_types ~w(immediate daily_digest weekly_digest off)

  schema "user_notification_preferences" do
    belongs_to :user, Assetronics.Accounts.User

    field :notification_type, :string
    field :email_enabled, :boolean, default: true
    field :in_app_enabled, :boolean, default: true
    field :sms_enabled, :boolean, default: false
    field :push_enabled, :boolean, default: false
    field :frequency, :string, default: "immediate"
    field :respect_quiet_hours, :boolean, default: true

    timestamps()
  end

  @doc false
  def changeset(preference, attrs) do
    preference
    |> cast(attrs, [
      :user_id,
      :notification_type,
      :email_enabled,
      :in_app_enabled,
      :sms_enabled,
      :push_enabled,
      :frequency,
      :respect_quiet_hours
    ])
    |> validate_required([:user_id, :notification_type])
    |> validate_inclusion(:notification_type, @notification_types)
    |> validate_inclusion(:frequency, @frequency_types)
    |> unique_constraint([:user_id, :notification_type])
    |> foreign_key_constraint(:user_id)
  end

  def notification_types, do: @notification_types
  def frequency_types, do: @frequency_types
end
