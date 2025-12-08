defmodule AssetronicsWeb.WebhookController do
  use AssetronicsWeb, :controller

  alias Assetronics.Integrations
  alias Assetronics.Integrations.Adapters.Jamf.Webhook, as: JamfWebhook
  alias Assetronics.Integrations.Adapters.BambooHR.Webhook, as: BambooHRWebhook
  alias Assetronics.Integrations.Adapters.Okta.Webhook, as: OktaWebhook
  alias Assetronics.Integrations.Adapters.Precoro.Webhook, as: PrecoroWebhook
  require Logger

  @doc """
  Receiver for BambooHR webhooks.

  Supports various webhook formats:
  - Event-based: {"event": "employee.created", "employee_id": "123"}
  - Batch update: {"employees": ["123", "456", "789"]}
  - Legacy format: {"employees": [{"id": "123", "firstName": "John", ...}]}

  Configure the webhook URL in BambooHR as:
  POST /api/v1/webhooks/bamboohr?tenant=your_tenant_id

  Optional: Include webhook secret in integration config for signature verification.
  """
  def bamboohr(conn, params) do
    # 1. Identify Tenant
    tenant = conn.query_params["tenant"]

    if is_nil(tenant) do
      Logger.error("BambooHR webhook received without tenant identifier")
      send_resp(conn, 400, "Missing tenant identifier")
    else
      # 2. Get integration and verify it exists
      case Integrations.get_integration_by_provider(tenant, "bamboohr") do
        nil ->
          Logger.error("BambooHR webhook received for tenant #{tenant} but no integration found")
          send_resp(conn, 404, "Integration not found")

        integration ->
          # 3. Verify webhook signature if configured
          with :ok <- verify_webhook_signature(conn, integration) do
            Logger.info("Received BambooHR webhook for tenant #{tenant}")

            # 4. Process webhook asynchronously
            Task.start(fn ->
              case BambooHRWebhook.process_webhook(tenant, transform_payload(params)) do
                {:ok, result} ->
                  Logger.info("BambooHR webhook processed successfully: #{inspect(result)}")

                {:error, reason} ->
                  Logger.error("BambooHR webhook processing failed: #{inspect(reason)}")
              end
            end)

            send_resp(conn, 200, "Webhook received")
          else
            {:error, :invalid_signature} ->
              Logger.warning("BambooHR webhook signature verification failed for tenant #{tenant}")
              send_resp(conn, 401, "Invalid signature")

            _ ->
              send_resp(conn, 500, "Internal error")
          end
      end
    end
  end

  # Helper to verify webhook signature if configured
  defp verify_webhook_signature(conn, integration) do
    webhook_secret = integration.auth_config["webhook_secret"]

    if webhook_secret do
      signature = get_req_header(conn, "x-bamboohr-signature") |> List.first()
      raw_body = conn.assigns[:raw_body] || ""

      BambooHRWebhook.verify_signature(raw_body, signature || "", webhook_secret)
    else
      # No secret configured, skip verification
      :ok
    end
  end

  # Helper to transform legacy payload format to new format
  defp transform_payload(%{"employees" => employees} = params) when is_list(employees) do
    # Check if it's a list of IDs or full employee objects
    case List.first(employees) do
      id when is_binary(id) ->
        # List of IDs - batch update format
        %{
          "event" => "employees.batch_update",
          "employee_ids" => employees
        }

      %{"id" => _} ->
        # List of employee objects - extract IDs
        %{
          "event" => "employees.batch_update",
          "employee_ids" => Enum.map(employees, & &1["id"])
        }

      _ ->
        params
    end
  end

  defp transform_payload(params), do: params

  @doc """
  Receiver for Jamf Pro webhooks.

  Jamf Pro sends webhooks for various device events including:
  - ComputerAdded, ComputerCheckIn, ComputerInventoryCompleted
  - MobileDeviceEnrolled, MobileDeviceCheckIn, MobileDeviceUnEnrolled

  Configure the webhook URL in Jamf Pro as:
  POST /api/v1/webhooks/jamf?tenant=your_tenant_id

  Expected payload format (from Jamf Pro):
  {
    "webhook": {
      "webhookEvent": "ComputerCheckIn",
      "id": 1,
      "name": "My Webhook",
      "event": {
        "computer": { ... }
      }
    }
  }
  """
  def jamf(conn, params) do
    tenant = conn.query_params["tenant"]

    if is_nil(tenant) do
      Logger.error("Jamf webhook received without tenant identifier")
      send_resp(conn, 400, "Missing tenant identifier")
    else
      case JamfWebhook.validate_payload(params) do
        {:error, reason} ->
          Logger.warning("Jamf webhook validation failed: #{reason}")
          send_resp(conn, 400, reason)

        :ok ->
          case Integrations.get_integration_by_provider(tenant, "jamf") do
            nil ->
              Logger.error("Jamf webhook received for tenant #{tenant} but no integration found")
              send_resp(conn, 404, "Integration not found")

            integration ->
              event_type = params["webhook"]["webhookEvent"] || params["event"] || "unknown"
              Logger.info("Received Jamf webhook for tenant #{tenant}: #{event_type}")

              Task.start(fn ->
                case JamfWebhook.process_webhook(tenant, integration, params) do
                  {:ok, result} ->
                    Logger.info("Jamf webhook processed: #{inspect(result)}")

                  {:error, reason} ->
                    Logger.error("Jamf webhook processing failed: #{inspect(reason)}")
                end
              end)

              send_resp(conn, 200, "Webhook received")
          end
      end
    end
  end

  @doc """
  Handles Okta event hook verification (GET request).

  When you first register an event hook in Okta, it sends a GET request
  with X-Okta-Verification-Challenge header that must be echoed back.
  """
  def okta_verify(conn, _params) do
    verification_challenge = get_req_header(conn, "x-okta-verification-challenge") |> List.first()

    if verification_challenge do
      Logger.info("Received Okta verification challenge")
      json(conn, %{"verification" => verification_challenge})
    else
      Logger.error("Okta verification request missing challenge header")
      send_resp(conn, 400, "Missing verification challenge")
    end
  end

  @doc """
  Receiver for Okta event hooks.

  Okta sends event hooks for user lifecycle events including:
  - user.lifecycle.create, user.lifecycle.activate
  - user.lifecycle.deactivate, user.lifecycle.suspend
  - user.lifecycle.unsuspend, user.lifecycle.delete

  Configure the event hook URL in Okta as:
  POST /api/v1/webhooks/okta?tenant=your_tenant_id

  Okta requires one-time verification when registering the event hook.
  The verification request includes X-Okta-Verification-Challenge header.
  """
  def okta(conn, params) do
    tenant = conn.query_params["tenant"]

    if is_nil(tenant) do
      Logger.error("Okta event hook received without tenant identifier")
      send_resp(conn, 400, "Missing tenant identifier")
    else
      case Integrations.get_integration_by_provider(tenant, "okta") do
        {:error, :not_found} ->
          Logger.error("Okta event hook received for tenant #{tenant} but no integration found")
          send_resp(conn, 404, "Integration not found")

        {:ok, integration} ->
          # Verify event hook signature if configured
          with :ok <- verify_okta_signature(conn, integration) do
            Logger.info("Received Okta event hook for tenant #{tenant}")

            # Process event hook asynchronously
            Task.start(fn ->
              case OktaWebhook.process_webhook(tenant, params) do
                {:ok, result} ->
                  Logger.info("Okta event hook processed successfully: #{inspect(result)}")

                {:error, reason} ->
                  Logger.error("Okta event hook processing failed: #{inspect(reason)}")
              end
            end)

            send_resp(conn, 200, "Event hook received")
          else
            {:error, :invalid_signature} ->
              Logger.warning("Okta event hook signature verification failed for tenant #{tenant}")
              send_resp(conn, 401, "Invalid signature")

            _ ->
              send_resp(conn, 500, "Internal error")
          end
      end
    end
  end

  # Helper to verify Okta event hook signature
  defp verify_okta_signature(conn, integration) do
    auth_config = integration.auth_config || %{}
    event_hook_secret = auth_config["event_hook_secret"]

    if event_hook_secret do
      signature = get_req_header(conn, "x-okta-event-hook-signature") |> List.first()
      raw_body = conn.assigns[:raw_body] || ""

      OktaWebhook.verify_signature(raw_body, signature || "", event_hook_secret)
    else
      # No secret configured, skip verification
      :ok
    end
  end

  @doc """
  Receiver for Precoro webhooks.

  Precoro sends webhooks for various procurement events including:
  - Purchase Order created (type: 2, action: 0)
  - Purchase Order updated (type: 2, action: 1)
  - Invoice created/updated (type: 3)
  - Supplier created/updated (type: 7)

  Configure the webhook URL in Precoro as:
  POST /api/v1/webhooks/precoro?tenant=your_tenant_id

  Expected payload format (from Precoro):
  {
    "id": 123456,
    "type": 2,
    "action": 0,
    "idn": 5
  }

  Where:
  - id: Entity ID
  - type: Entity type (2 = Purchase Order)
  - action: Action type (0 = Create, 1 = Update)
  - idn: Additional identifier
  """
  def precoro(conn, params) do
    tenant = conn.query_params["tenant"]

    if is_nil(tenant) do
      Logger.error("Precoro webhook received without tenant identifier")
      send_resp(conn, 400, "Missing tenant identifier")
    else
      case PrecoroWebhook.validate_payload(params) do
        {:error, reason} ->
          Logger.warning("Precoro webhook validation failed: #{reason}")
          send_resp(conn, 400, reason)

        :ok ->
          case Integrations.get_integration_by_provider(tenant, "precoro") do
            {:error, :not_found} ->
              Logger.error("Precoro webhook received for tenant #{tenant} but no integration found")
              send_resp(conn, 404, "Integration not found")

            {:ok, _integration} ->
              event_type = "type_#{params["type"]}_action_#{params["action"]}"
              Logger.info("Received Precoro webhook for tenant #{tenant}: #{event_type}")

              Task.start(fn ->
                case PrecoroWebhook.process_webhook(tenant, params) do
                  {:ok, result} ->
                    Logger.info("Precoro webhook processed: #{inspect(result)}")

                  {:error, reason} ->
                    Logger.error("Precoro webhook processing failed: #{inspect(reason)}")
                end
              end)

              send_resp(conn, 200, "Webhook received")
          end
      end
    end
  end
end
