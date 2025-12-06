defmodule AssetronicsWeb.UserPreferencesJSON do
  alias Assetronics.Settings.UserNotificationPreference

  def index(%{preferences: preferences}) do
    %{data: Enum.map(preferences, fn {_type, pref} -> data(pref) end)}
  end

  def show(%{preference: preference}) do
    %{data: data(preference)}
  end

  defp data(%UserNotificationPreference{} = preference) do
    %{
      id: preference.id,
      user_id: preference.user_id,
      notification_type: preference.notification_type,
      channels: %{
        email: preference.email_enabled,
        in_app: preference.in_app_enabled,
        sms: preference.sms_enabled,
        push: preference.push_enabled
      },
      frequency: preference.frequency,
      respect_quiet_hours: preference.respect_quiet_hours,
      inserted_at: preference.inserted_at,
      updated_at: preference.updated_at
    }
  end
end
