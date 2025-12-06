defmodule Assetronics.Integrations.Adapters.Slack do
  @moduledoc """
  Slack integration adapter for sending notifications and messages.

  Slack API Documentation: https://api.slack.com/methods

  Authentication: Bot Token (OAuth 2.0)
  Base URL: https://slack.com/api
  """

  @behaviour Assetronics.Integrations.Adapter

  alias Assetronics.Integrations.Integration

  require Logger

  @impl true
  def test_connection(%Integration{} = integration) do
    client = build_client(integration)

    # Test with auth.test endpoint
    case Tesla.get(client, "/auth.test") do
      {:ok, %Tesla.Env{status: 200, body: %{"ok" => true} = body}} ->
        {:ok, %{
          status: "connected",
          message: "Successfully connected to Slack",
          team: body["team"],
          user: body["user"]
        }}

      {:ok, %Tesla.Env{status: 200, body: %{"ok" => false, "error" => error}}} ->
        {:error, error}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def sync(_tenant, %Integration{} = _integration) do
    # Slack doesn't have a traditional "sync" - it's used for notifications
    # Return empty sync result
    {:ok, %{message: "Slack is a notification-only integration"}}
  end

  @doc """
  Sends a message to a Slack channel.
  """
  def send_message(%Integration{} = integration, channel, text, opts \\ []) do
    client = build_client(integration)

    body = %{
      channel: channel,
      text: text,
      blocks: opts[:blocks],
      attachments: opts[:attachments],
      thread_ts: opts[:thread_ts],
      reply_broadcast: opts[:reply_broadcast]
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()

    case Tesla.post(client, "/chat.postMessage", body) do
      {:ok, %Tesla.Env{status: 200, body: %{"ok" => true} = response}} ->
        {:ok, response}

      {:ok, %Tesla.Env{status: 200, body: %{"ok" => false, "error" => error}}} ->
        {:error, error}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Sends a notification about an asset assignment.
  """
  def notify_asset_assignment(integration, asset, employee, channel \\ nil) do
    channel = channel || get_default_channel(integration)

    blocks = [
      %{
        type: "header",
        text: %{
          type: "plain_text",
          text: "🎉 Asset Assigned"
        }
      },
      %{
        type: "section",
        fields: [
          %{
            type: "mrkdwn",
            text: "*Asset:*\n#{asset.name}"
          },
          %{
            type: "mrkdwn",
            text: "*Asset Tag:*\n#{asset.asset_tag}"
          },
          %{
            type: "mrkdwn",
            text: "*Assigned To:*\n#{employee.first_name} #{employee.last_name}"
          },
          %{
            type: "mrkdwn",
            text: "*Email:*\n#{employee.email}"
          }
        ]
      }
    ]

    send_message(integration, channel, "Asset #{asset.asset_tag} assigned to #{employee.email}", blocks: blocks)
  end

  @doc """
  Sends a notification about workflow completion.
  """
  def notify_workflow_complete(integration, workflow, channel \\ nil) do
    channel = channel || get_default_channel(integration)

    emoji = case workflow.workflow_type do
      "onboarding" -> "👋"
      "offboarding" -> "👋"
      "maintenance" -> "🔧"
      "audit" -> "📋"
      _ -> "✅"
    end

    blocks = [
      %{
        type: "header",
        text: %{
          type: "plain_text",
          text: "#{emoji} Workflow Completed"
        }
      },
      %{
        type: "section",
        fields: [
          %{
            type: "mrkdwn",
            text: "*Workflow:*\n#{workflow.title}"
          },
          %{
            type: "mrkdwn",
            text: "*Type:*\n#{workflow.workflow_type}"
          },
          %{
            type: "mrkdwn",
            text: "*Status:*\n#{workflow.status}"
          },
          %{
            type: "mrkdwn",
            text: "*Completed At:*\n#{format_datetime(workflow.completed_at)}"
          }
        ]
      }
    ]

    send_message(integration, channel, "Workflow '#{workflow.title}' completed", blocks: blocks)
  end

  @doc """
  Sends a notification about an overdue workflow.
  """
  def notify_workflow_overdue(integration, workflow, channel \\ nil) do
    channel = channel || get_default_channel(integration)

    blocks = [
      %{
        type: "header",
        text: %{
          type: "plain_text",
          text: "⚠️ Overdue Workflow Alert"
        }
      },
      %{
        type: "section",
        fields: [
          %{
            type: "mrkdwn",
            text: "*Workflow:*\n#{workflow.title}"
          },
          %{
            type: "mrkdwn",
            text: "*Type:*\n#{workflow.workflow_type}"
          },
          %{
            type: "mrkdwn",
            text: "*Due Date:*\n#{workflow.due_date}"
          },
          %{
            type: "mrkdwn",
            text: "*Assigned To:*\n#{workflow.assigned_to || "Unassigned"}"
          }
        ]
      },
      %{
        type: "context",
        elements: [
          %{
            type: "mrkdwn",
            text: "This workflow is overdue and requires attention."
          }
        ]
      }
    ]

    send_message(integration, channel, "Workflow '#{workflow.title}' is overdue!", blocks: blocks)
  end

  @doc """
  Sends a notification about a new employee onboarding.
  """
  def notify_new_employee(integration, employee, channel \\ nil) do
    channel = channel || get_default_channel(integration)

    blocks = [
      %{
        type: "header",
        text: %{
          type: "plain_text",
          text: "👋 Welcome New Team Member!"
        }
      },
      %{
        type: "section",
        fields: [
          %{
            type: "mrkdwn",
            text: "*Name:*\n#{employee.first_name} #{employee.last_name}"
          },
          %{
            type: "mrkdwn",
            text: "*Email:*\n#{employee.email}"
          },
          %{
            type: "mrkdwn",
            text: "*Job Title:*\n#{employee.job_title || "N/A"}"
          },
          %{
            type: "mrkdwn",
            text: "*Department:*\n#{employee.department || "N/A"}"
          }
        ]
      }
    ]

    send_message(integration, channel, "Welcome #{employee.first_name} #{employee.last_name}!", blocks: blocks)
  end

  # Private functions

  defp build_client(%Integration{} = integration) do
    base_url = integration.base_url || "https://slack.com/api"
    bot_token = integration.api_key || integration.access_token

    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Headers, [
        {"authorization", "Bearer #{bot_token}"},
        {"content-type", "application/json; charset=utf-8"}
      ]},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Timeout, timeout: 10_000}
    ]

    Tesla.client(middleware)
  end

  defp get_default_channel(%Integration{} = integration) do
    case integration.auth_config do
      %{"default_channel" => channel} -> channel
      _ -> "#general"
    end
  end

  defp format_datetime(nil), do: "N/A"
  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")
  end
end
