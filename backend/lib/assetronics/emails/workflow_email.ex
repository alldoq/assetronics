defmodule Assetronics.Emails.WorkflowEmail do
  @moduledoc """
  Email templates for workflow-related notifications.
  """

  import Swoosh.Email

  alias Assetronics.Accounts.User
  alias Assetronics.Workflows.Workflow

  @doc """
  Sends a workflow assignment notification email.
  """
  def workflow_assigned(%User{} = user, %Workflow{} = workflow, execution, tenant) do
    app_url = Application.get_env(:assetronics, :app_url)
    workflow_url = "#{app_url}/workflows/#{execution.id}"

    new()
    |> from(from_address())
    |> to({full_name(user), user.email})
    |> subject("New workflow assigned: #{workflow.title}")
    |> html_body("""
    <html>
      <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background-color: #f8f9fa; border-radius: 8px; padding: 30px;">
          <h1 style="color: #333; margin-bottom: 20px;">Workflow Assigned</h1>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            Hi #{user.first_name || "there"},
          </p>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            A new workflow has been assigned to you in your <strong>#{tenant}</strong> workspace.
          </p>

          <div style="background-color: white; border: 2px solid #e9ecef; border-radius: 8px; padding: 20px; margin: 20px 0;">
            <h3 style="color: #333; margin-top: 0;">#{workflow.title}</h3>
            #{if workflow.description, do: "<p style='color: #666; margin: 10px 0;'>#{workflow.description}</p>", else: ""}
            #{if execution.due_date, do: "<p style='color: #dc3545; font-weight: bold; margin: 10px 0;'>⏰ Due: #{format_date(execution.due_date)}</p>", else: ""}
          </div>

          <div style="margin: 30px 0;">
            <a href="#{workflow_url}"
               style="background-color: #007bff; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
              Start Workflow
            </a>
          </div>

          <p style="color: #777; font-size: 14px; line-height: 1.6;">
            Please complete this workflow by the due date. If you have any questions, contact your manager.
          </p>
        </div>
      </body>
    </html>
    """)
    |> text_body("""
    Workflow Assigned

    Hi #{user.first_name || "there"},

    A new workflow has been assigned to you in your #{tenant} workspace.

    Workflow: #{workflow.title}
    #{if workflow.description, do: "Description: #{workflow.description}\n", else: ""}#{if execution.due_date, do: "⏰ Due: #{format_date(execution.due_date)}\n", else: ""}
    Start workflow: #{workflow_url}

    Please complete this workflow by the due date. If you have any questions, contact your manager.
    """)
  end

  @doc """
  Sends a workflow completion confirmation email.
  """
  def workflow_completed(%User{} = user, %Workflow{} = workflow, _tenant) do
    app_url = Application.get_env(:assetronics, :app_url)

    new()
    |> from(from_address())
    |> to({full_name(user), user.email})
    |> subject("Workflow completed: #{workflow.title}")
    |> html_body("""
    <html>
      <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background-color: #f8f9fa; border-radius: 8px; padding: 30px;">
          <h1 style="color: #28a745; margin-bottom: 20px;">✓ Workflow Completed</h1>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            Hi #{user.first_name || "there"},
          </p>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            Great work! You've successfully completed the <strong>#{workflow.title}</strong> workflow.
          </p>

          <div style="background-color: #d4edda; border-left: 4px solid #28a745; padding: 15px; margin: 20px 0;">
            <p style="color: #155724; font-size: 14px; margin: 0;">
              ✓ All tasks have been completed
            </p>
          </div>

          <div style="margin: 30px 0;">
            <a href="#{app_url}/workflows"
               style="background-color: #28a745; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
              View All Workflows
            </a>
          </div>
        </div>
      </body>
    </html>
    """)
    |> text_body("""
    ✓ Workflow Completed

    Hi #{user.first_name || "there"},

    Great work! You've successfully completed the #{workflow.title} workflow.

    ✓ All tasks have been completed

    View all workflows: #{app_url}/workflows
    """)
  end

  @doc """
  Sends a workflow overdue notification email.
  """
  def workflow_overdue(%User{} = user, %Workflow{} = workflow, execution, days_overdue, _tenant) do
    app_url = Application.get_env(:assetronics, :app_url)
    workflow_url = "#{app_url}/workflows/#{execution.id}"

    new()
    |> from(from_address())
    |> to({full_name(user), user.email})
    |> subject("OVERDUE: Workflow - #{workflow.title}")
    |> html_body("""
    <html>
      <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background-color: #f8f9fa; border-radius: 8px; padding: 30px;">
          <h1 style="color: #dc3545; margin-bottom: 20px;">⚠️ Workflow Overdue</h1>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            Hi #{user.first_name || "there"},
          </p>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            The following workflow is <strong style="color: #dc3545;">#{days_overdue} days overdue</strong>.
          </p>

          <div style="background-color: white; border: 2px solid #dc3545; border-radius: 8px; padding: 20px; margin: 20px 0;">
            <h3 style="color: #333; margin-top: 0;">#{workflow.title}</h3>
            <p style="color: #dc3545; font-weight: bold; margin: 10px 0;">
              ⏰ Was due: #{format_date(execution.due_date)}
            </p>
            <p style="color: #666; margin: 10px 0;">
              Current status: #{execution.status}
            </p>
          </div>

          <div style="margin: 30px 0;">
            <a href="#{workflow_url}"
               style="background-color: #dc3545; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
              Complete Workflow Now
            </a>
          </div>

          <p style="color: #777; font-size: 14px; line-height: 1.6;">
            Please complete this workflow as soon as possible. Contact your manager if you need assistance.
          </p>
        </div>
      </body>
    </html>
    """)
    |> text_body("""
    ⚠️ Workflow Overdue

    Hi #{user.first_name || "there"},

    The following workflow is #{days_overdue} days overdue.

    Workflow: #{workflow.title}
    Was due: #{format_date(execution.due_date)}
    Current status: #{execution.status}

    Complete workflow: #{workflow_url}

    Please complete this workflow as soon as possible. Contact your manager if you need assistance.
    """)
  end

  @doc """
  Sends a workflow step reminder email.
  """
  def workflow_step_reminder(%User{} = user, %Workflow{} = workflow, step_name, _tenant) do
    app_url = Application.get_env(:assetronics, :app_url)

    new()
    |> from(from_address())
    |> to({full_name(user), user.email})
    |> subject("Reminder: Complete workflow step - #{step_name}")
    |> html_body("""
    <html>
      <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background-color: #f8f9fa; border-radius: 8px; padding: 30px;">
          <h1 style="color: #333; margin-bottom: 20px;">Workflow Step Reminder</h1>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            Hi #{user.first_name || "there"},
          </p>

          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            This is a reminder to complete the following step in your workflow:
          </p>

          <div style="background-color: white; border: 2px solid #ffc107; border-radius: 8px; padding: 20px; margin: 20px 0;">
            <h3 style="color: #333; margin-top: 0;">#{workflow.title}</h3>
            <p style="color: #856404; font-weight: bold; margin: 10px 0;">
              Current step: #{step_name}
            </p>
          </div>

          <div style="margin: 30px 0;">
            <a href="#{app_url}/workflows"
               style="background-color: #ffc107; color: #000; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
              Continue Workflow
            </a>
          </div>
        </div>
      </body>
    </html>
    """)
    |> text_body("""
    Workflow Step Reminder

    Hi #{user.first_name || "there"},

    This is a reminder to complete the following step in your workflow:

    Workflow: #{workflow.title}
    Current step: #{step_name}

    Continue workflow: #{app_url}/workflows
    """)
  end

  # Private helper functions

  defp from_address do
    email = Application.get_env(:assetronics, :from_email)
    name = Application.get_env(:assetronics, :from_name)
    {name, email}
  end

  defp full_name(%User{first_name: first, last_name: last}) when is_binary(first) and is_binary(last) do
    "#{first} #{last}"
  end

  defp full_name(%User{first_name: first}) when is_binary(first), do: first
  defp full_name(%User{}), do: nil

  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%B %d, %Y")
  defp format_date(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%B %d, %Y")
  defp format_date(_), do: "N/A"
end
