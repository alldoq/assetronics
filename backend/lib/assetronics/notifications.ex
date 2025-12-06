defmodule Assetronics.Notifications do
  @moduledoc """
  The Notifications context handles sending notifications to users across multiple channels.

  Respects user notification preferences and tenant settings including:
  - Channel preferences (email, in_app, SMS, push)
  - Frequency settings (immediate, daily digest, weekly digest, off)
  - Quiet hours
  """

  require Logger
  alias Assetronics.Settings

  @doc """
  Sends a notification to a user, respecting their preferences.

  ## Parameters
    - tenant: The tenant slug
    - user_id: The user UUID
    - notification_type: One of the valid notification types (e.g., "asset_assigned")
    - data: Map with notification data (title, body, etc.)

  ## Examples
      iex> notify(
        "acme",
        user_id,
        "asset_assigned",
        %{
          title: "Asset Assigned",
          body: "MacBook Pro has been assigned to you",
          asset_id: asset_id
        }
      )
      :ok
  """
  def notify(tenant, user_id, notification_type, data) do
    channels_to_send = get_enabled_channels(tenant, user_id, notification_type)

    Enum.each(channels_to_send, fn channel ->
      send_via_channel(tenant, user_id, channel, notification_type, data)
    end)

    :ok
  end

  @doc """
  Gets the list of channels that should receive the notification based on user preferences.
  """
  def get_enabled_channels(tenant, user_id, notification_type) do
    [:email, :in_app, :sms, :push]
    |> Enum.filter(fn channel ->
      Settings.should_notify?(tenant, user_id, notification_type, channel)
    end)
  end

  # Send notification via specific channel
  defp send_via_channel(tenant, user_id, :email, notification_type, data) do
    start_time = System.monotonic_time()
    Logger.info("[Notifications] Sending email notification: #{notification_type} to user #{user_id}")

    result = case Assetronics.Notifications.Email.send_notification(tenant, user_id, notification_type, data) do
      {:ok, _} ->
        Logger.info("[Notifications] Email sent successfully")
        :ok

      {:error, reason} ->
        Logger.error("[Notifications] Failed to send email: #{inspect(reason)}")
        {:error, reason}
    end

    # Emit telemetry
    duration = System.monotonic_time() - start_time
    case result do
      :ok ->
        :telemetry.execute(
          [:assetronics, :notifications, :send, :stop],
          %{duration: duration},
          %{tenant: tenant, channel: "email", status: :success}
        )
        :telemetry.execute(
          [:assetronics, :notifications, :send, :success],
          %{count: 1},
          %{tenant: tenant, channel: "email"}
        )

      {:error, _} ->
        :telemetry.execute(
          [:assetronics, :notifications, :send, :stop],
          %{duration: duration},
          %{tenant: tenant, channel: "email", status: :failure}
        )
        :telemetry.execute(
          [:assetronics, :notifications, :send, :failure],
          %{count: 1},
          %{tenant: tenant, channel: "email"}
        )
    end

    result
  end

  defp send_via_channel(tenant, user_id, :in_app, notification_type, data) do
    start_time = System.monotonic_time()
    Logger.info("[Notifications] Sending in-app notification: #{notification_type} to user #{user_id}")

    result = case Assetronics.Notifications.InApp.create_and_broadcast(tenant, user_id, notification_type, data) do
      {:ok, _notification} ->
        Logger.info("[Notifications] In-app notification created and broadcasted successfully")
        :ok

      {:error, reason} ->
        Logger.error("[Notifications] Failed to create in-app notification: #{inspect(reason)}")
        {:error, reason}
    end

    # Emit telemetry
    duration = System.monotonic_time() - start_time
    case result do
      :ok ->
        :telemetry.execute(
          [:assetronics, :notifications, :send, :stop],
          %{duration: duration},
          %{tenant: tenant, channel: "in_app", status: :success}
        )
        :telemetry.execute(
          [:assetronics, :notifications, :send, :success],
          %{count: 1},
          %{tenant: tenant, channel: "in_app"}
        )

      {:error, _} ->
        :telemetry.execute(
          [:assetronics, :notifications, :send, :stop],
          %{duration: duration},
          %{tenant: tenant, channel: "in_app", status: :failure}
        )
        :telemetry.execute(
          [:assetronics, :notifications, :send, :failure],
          %{count: 1},
          %{tenant: tenant, channel: "in_app"}
        )
    end

    result
  end

  defp send_via_channel(tenant, user_id, :sms, notification_type, data) do
    Logger.info("[Notifications] Sending SMS notification: #{notification_type} to user #{user_id}")

    case Assetronics.Notifications.SMS.send_notification(tenant, user_id, notification_type, data) do
      {:ok, _response} ->
        Logger.info("[Notifications] SMS sent successfully")
        :ok

      {:error, reason} ->
        Logger.error("[Notifications] Failed to send SMS: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp send_via_channel(tenant, user_id, :push, notification_type, data) do
    Logger.info("[Notifications] Sending push notification: #{notification_type} to user #{user_id}")

    Assetronics.Notifications.Push.send_notification(tenant, user_id, notification_type, data)
  end
end
