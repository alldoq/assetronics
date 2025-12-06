defmodule Assetronics.Settings do
  @moduledoc """
  The Settings context handles system configuration and user preferences.

  Manages both tenant-wide system settings and per-user notification preferences.
  """

  import Ecto.Query, warn: false
  alias Assetronics.Repo
  alias Assetronics.Settings.{TenantSettings, UserNotificationPreference}

  ## Tenant Settings

  @doc """
  Gets the tenant settings, creating default settings if none exist.
  """
  def get_tenant_settings(tenant) do
    query = from t in TenantSettings
    case Repo.one(query, prefix: Triplex.to_prefix(tenant)) do
      nil -> create_default_tenant_settings(tenant)
      settings -> {:ok, settings}
    end
  end

  @doc """
  Updates the tenant settings.
  """
  def update_tenant_settings(tenant, attrs) do
    with {:ok, settings} <- get_tenant_settings(tenant) do
      settings
      |> TenantSettings.changeset(attrs)
      |> Repo.update(prefix: Triplex.to_prefix(tenant))
    end
  end

  @doc """
  Creates default tenant settings.
  """
  def create_default_tenant_settings(tenant) do
    %TenantSettings{}
    |> TenantSettings.changeset(%{})
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
  end

  ## User Notification Preferences

  @doc """
  Gets all notification preferences for a user.
  Returns a map of notification_type => preference.
  """
  def get_user_notification_preferences(tenant, user_id) do
    preferences =
      Repo.all(
        from(p in UserNotificationPreference, where: p.user_id == ^user_id),
        prefix: Triplex.to_prefix(tenant)
      )

    {:ok, Enum.into(preferences, %{}, fn pref -> {pref.notification_type, pref} end)}
  end

  @doc """
  Gets a specific notification preference for a user and notification type.
  Creates default if it doesn't exist.
  """
  def get_user_notification_preference(tenant, user_id, notification_type) do
    case Repo.one(
      from(p in UserNotificationPreference,
        where: p.user_id == ^user_id and p.notification_type == ^notification_type
      ),
      prefix: Triplex.to_prefix(tenant)
    ) do
      nil -> create_default_notification_preference(tenant, user_id, notification_type)
      preference -> {:ok, preference}
    end
  end

  @doc """
  Updates or creates a user's notification preference.
  """
  def upsert_notification_preference(tenant, user_id, notification_type, attrs) do
    case get_user_notification_preference(tenant, user_id, notification_type) do
      {:ok, preference} ->
        preference
        |> UserNotificationPreference.changeset(attrs)
        |> Repo.update(prefix: Triplex.to_prefix(tenant))

      {:error, _} ->
        %UserNotificationPreference{user_id: user_id, notification_type: notification_type}
        |> UserNotificationPreference.changeset(attrs)
        |> Repo.insert(prefix: Triplex.to_prefix(tenant))
    end
  end

  @doc """
  Creates default notification preferences for a user (all notification types).
  """
  def create_default_preferences_for_user(tenant, user_id) do
    results =
      UserNotificationPreference.notification_types()
      |> Enum.map(fn type ->
        create_default_notification_preference(tenant, user_id, type)
      end)

    case Enum.find(results, fn {status, _} -> status == :error end) do
      nil -> {:ok, results}
      error -> error
    end
  end

  @doc """
  Creates a default notification preference for a specific notification type.
  """
  def create_default_notification_preference(tenant, user_id, notification_type) do
    %UserNotificationPreference{
      user_id: user_id,
      notification_type: notification_type,
      email_enabled: default_email_enabled?(notification_type),
      in_app_enabled: true,
      sms_enabled: false,
      push_enabled: false,
      frequency: "immediate",
      respect_quiet_hours: true
    }
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
  end

  ## Helper Functions

  @doc """
  Gets Twilio configuration from environment variables.
  Returns nil if Twilio is not configured.
  """
  def get_twilio_config do
    account_sid = System.get_env("TWILIO_ACCOUNT_SID")
    auth_token = System.get_env("TWILIO_AUTH_TOKEN")
    from_number = System.get_env("TWILIO_FROM_NUMBER")

    if account_sid && auth_token && from_number do
      %{
        account_sid: account_sid,
        auth_token: auth_token,
        from_number: from_number
      }
    else
      nil
    end
  end

  @doc """
  Checks if Twilio SMS is configured via environment variables.
  """
  def twilio_configured? do
    !is_nil(get_twilio_config())
  end

  @doc """
  Checks if a user should receive a notification via a specific channel.
  Takes into account quiet hours and user preferences.
  """
  def should_notify?(tenant, user_id, notification_type, channel) do
    with {:ok, preference} <- get_user_notification_preference(tenant, user_id, notification_type),
         {:ok, tenant_settings} <- get_tenant_settings(tenant) do
      # Check if channel is enabled
      channel_enabled = case channel do
        :email -> preference.email_enabled
        :in_app -> preference.in_app_enabled
        :sms -> preference.sms_enabled && twilio_configured?()
        :push -> preference.push_enabled
        _ -> false
      end

      # Check quiet hours if applicable
      in_quiet_hours = preference.respect_quiet_hours && in_quiet_hours?(tenant_settings)

      channel_enabled && !in_quiet_hours
    else
      _ -> false
    end
  end

  @doc """
  Checks if the current time is within tenant's default quiet hours.
  """
  def in_quiet_hours?(%TenantSettings{} = settings) do
    if settings.default_quiet_hours_enabled do
      now = Time.utc_now()
      start_time = settings.default_quiet_hours_start
      end_time = settings.default_quiet_hours_end

      # Handle case where quiet hours span midnight
      if Time.compare(start_time, end_time) == :gt do
        Time.compare(now, start_time) != :lt || Time.compare(now, end_time) != :gt
      else
        Time.compare(now, start_time) != :lt && Time.compare(now, end_time) != :gt
      end
    else
      false
    end
  end

  ## Private Functions

  defp default_email_enabled?(notification_type) do
    notification_type in [
      "asset_assigned",
      "asset_returned",
      "workflow_assigned",
      "workflow_overdue",
      "security_alert"
    ]
  end
end
