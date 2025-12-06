defmodule Assetronics.Notifications.Email do
  @moduledoc """
  Handles email notifications using Swoosh.
  """

  import Swoosh.Email
  alias Assetronics.Mailer
  alias Assetronics.Settings
  alias Assetronics.Accounts

  @doc """
  Sends an email notification to a user.
  """
  def send_notification(tenant, user_id, notification_type, data) do
    try do
      user = Accounts.get_user!(tenant, user_id)
      {:ok, tenant_settings} = Settings.get_tenant_settings(tenant)
      email =
        new()
        |> to({user.first_name <> " " <> user.last_name, user.email})
        |> from({tenant_settings.email.from_name || "Assetronics",
                 tenant_settings.email.from_address || "noreply@assetronics.com"})
        |> subject(data[:title] || format_notification_title(notification_type))
        |> text_body(data[:body] || "You have a new notification")
        |> html_body(build_html_body(notification_type, data))

      email =
        if tenant_settings.email.reply_to do
          reply_to(email, tenant_settings.email.reply_to)
        else
          email
        end

      email =
        if tenant_settings.email.bcc_admin && tenant_settings.email.from_address do
          bcc(email, tenant_settings.email.from_address)
        else
          email
        end

      Mailer.deliver(email)
    rescue
      error ->
        {:error, error}
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

  defp build_html_body(notification_type, data) do
    """
    <html>
      <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #2c3e50;">#{data[:title] || format_notification_title(notification_type)}</h2>
          <p>#{data[:body] || "You have a new notification."}</p>
          #{if data[:action_url] do
            "<p style='margin-top: 30px;'>
              <a href='#{data[:action_url]}' style='display: inline-block; padding: 12px 24px; background-color: #3498db; color: white; text-decoration: none; border-radius: 4px;'>
                #{data[:action_text] || "View Details"}
              </a>
            </p>"
          else
            ""
          end}
          <hr style="margin-top: 30px; border: none; border-top: 1px solid #e0e0e0;">
          <p style="font-size: 12px; color: #7f8c8d;">
            This is an automated notification from Assetronics. You can manage your notification preferences in your account settings.
          </p>
        </div>
      </body>
    </html>
    """
  end
end
