defmodule Assetronics.Notifications.SMS do
  @moduledoc """
  Handles SMS notifications using Twilio.
  """

  require Logger
  alias Assetronics.Settings
  alias Assetronics.Accounts

  @doc """
  Sends an SMS notification to a user via Twilio.
  """
  def send_notification(tenant, user_id, notification_type, data) do
    with {:ok, twilio_config} <- get_twilio_config(),
         {:ok, user} <- get_user(tenant, user_id),
         {:ok, phone_number} <- get_user_phone(user) do
      message_body = build_message_body(notification_type, data)

      send_sms(twilio_config, phone_number, message_body)
    else
      {:error, :no_twilio_config} ->
        Logger.warning("[SMS] Twilio is not configured via environment variables")
        {:error, :twilio_not_configured}

      {:error, :no_phone_number} ->
        Logger.warning("[SMS] User #{user_id} does not have a phone number")
        {:error, :no_phone_number}

      {:error, reason} ->
        Logger.error("[SMS] Failed to send SMS: #{inspect(reason)}")
        {:error, reason}
    end
  end

  ## Private Functions

  defp get_twilio_config do
    case Settings.get_twilio_config() do
      nil -> {:error, :no_twilio_config}
      config -> {:ok, config}
    end
  end

  defp get_user(tenant, user_id) do
    try do
      user = Accounts.get_user!(tenant, user_id)
      {:ok, user}
    rescue
      _ -> {:error, :user_not_found}
    end
  end

  defp get_user_phone(user) do
    # Assuming users have a phone_number field
    # Adjust based on your User schema
    case Map.get(user, :phone_number) do
      nil -> {:error, :no_phone_number}
      "" -> {:error, :no_phone_number}
      phone -> {:ok, phone}
    end
  end

  defp build_message_body(notification_type, data) do
    title = data[:title] || format_notification_title(notification_type)
    body = data[:body] || ""

    "#{title}: #{body}"
  end

  defp send_sms(config, to_number, message) do
    url = "https://api.twilio.com/2010-04-01/Accounts/#{config.account_sid}/Messages.json"

    form_data = %{
      "From" => config.from_number,
      "To" => to_number,
      "Body" => message
    }

    auth = "#{config.account_sid}:#{config.auth_token}"

    case Req.post(url,
           auth: {:basic, auth},
           form: form_data
         ) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        Logger.info("[SMS] Successfully sent SMS to #{to_number}")
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.error("[SMS] Twilio API error (#{status}): #{inspect(body)}")
        {:error, {:twilio_api_error, status, body}}

      {:error, reason} ->
        Logger.error("[SMS] HTTP error: #{inspect(reason)}")
        {:error, {:http_error, reason}}
    end
  end

  defp format_notification_title("asset_assigned"), do: "Asset assigned to you"
  defp format_notification_title("asset_returned"), do: "Asset returned"
  defp format_notification_title("asset_due_soon"), do: "Asset due soon"
  defp format_notification_title("workflow_assigned"), do: "Workflow task assigned"
  defp format_notification_title("workflow_completed"), do: "Workflow completed"
  defp format_notification_title("workflow_overdue"), do: "Workflow overdue"
  defp format_notification_title("integration_sync_failed"), do: "Integration sync failed"
  defp format_notification_title("security_alert"), do: "Security alert"
  defp format_notification_title("system_announcement"), do: "System announcement"
  defp format_notification_title(_), do: "Notification"
end
