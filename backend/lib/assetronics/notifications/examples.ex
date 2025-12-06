defmodule Assetronics.Notifications.Examples do
  @moduledoc """
  Example functions showing how to send notifications.
  These can be called from anywhere in the application.
  """

  alias Assetronics.Notifications

  @doc """
  Example: Send notification when an asset is assigned to an employee.
  Call this from the Assets.assign_asset function.
  """
  def notify_asset_assigned(tenant, employee_id, asset) do
    Notifications.notify(
      tenant,
      employee_id,
      "asset_assigned",
      %{
        title: "Asset Assigned",
        body: "#{asset.name} has been assigned to you.",
        action_url: "https://app.assetronics.com/assets/#{asset.id}",
        action_text: "View Asset"
      }
    )
  end

  @doc """
  Example: Send notification when a workflow task is assigned.
  Call this from the Workflows context.
  """
  def notify_workflow_assigned(tenant, user_id, workflow) do
    Notifications.notify(
      tenant,
      user_id,
      "workflow_assigned",
      %{
        title: "Workflow Task Assigned",
        body: "You have been assigned: #{workflow.title}",
        action_url: "https://app.assetronics.com/workflows/#{workflow.id}",
        action_text: "View Workflow"
      }
    )
  end

  @doc """
  Example: Send notification when a workflow is overdue.
  Can be called from a background job that checks for overdue workflows.
  """
  def notify_workflow_overdue(tenant, user_id, workflow) do
    Notifications.notify(
      tenant,
      user_id,
      "workflow_overdue",
      %{
        title: "Workflow Overdue",
        body: "Your workflow task '#{workflow.title}' is overdue.",
        action_url: "https://app.assetronics.com/workflows/#{workflow.id}",
        action_text: "Complete Task"
      }
    )
  end

  @doc """
  Example: Send security alert.
  Can be called when suspicious activity is detected.
  """
  def notify_security_alert(tenant, user_id, alert_message) do
    Notifications.notify(
      tenant,
      user_id,
      "security_alert",
      %{
        title: "Security Alert",
        body: alert_message,
        action_url: "https://app.assetronics.com/settings/security",
        action_text: "Review Security Settings"
      }
    )
  end
end
