defmodule Assetronics.Integrations.Adapters.Okta.Webhook do
  @moduledoc """
  Handles event hooks from Okta for automatic data synchronization.

  Okta event hooks support user lifecycle events including:
  - user.lifecycle.create
  - user.lifecycle.activate
  - user.lifecycle.deactivate
  - user.lifecycle.suspend
  - user.lifecycle.unsuspend
  - user.lifecycle.delete
  """

  alias Assetronics.Integrations
  alias Assetronics.Integrations.Adapters.Okta.{Client, Api, EmployeeSync}

  require Logger

  @doc """
  Processes an incoming event hook from Okta.

  Okta sends event hooks with the following structure:
  {
    "eventType": "com.okta.event_hook",
    "eventTypeVersion": "1.0",
    "cloudEventsVersion": "0.1",
    "source": "https://{yourOktaDomain}/api/v1/eventHooks/{eventHookId}",
    "eventId": "unique-event-id",
    "data": {
      "events": [...]
    }
  }
  """
  def process_webhook(tenant, webhook_payload) do
    Logger.info("Processing Okta event hook for tenant: #{tenant}")

    with {:ok, integration} <- get_okta_integration(tenant),
         {:ok, result} <- process_event_hook(tenant, integration, webhook_payload) do
      Logger.info("Okta event hook processed successfully: #{inspect(result)}")
      {:ok, result}
    else
      {:error, reason} ->
        Logger.error("Failed to process Okta event hook: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Verifies the one-time verification challenge from Okta.

  When you first register an event hook, Okta sends a verification request
  with an X-Okta-Verification-Challenge header that you must echo back.
  """
  def verify_challenge(challenge_header) do
    if challenge_header do
      {:ok, challenge_header}
    else
      {:error, :missing_challenge}
    end
  end

  @doc """
  Validates the event hook signature from Okta.

  Okta signs event hooks using a shared secret and HMAC-SHA256.
  """
  def verify_signature(payload, signature_header, secret) do
    if secret do
      expected_signature =
        :crypto.mac(:hmac, :sha256, secret, payload)
        |> Base.encode64()

      if Plug.Crypto.secure_compare(expected_signature, signature_header || "") do
        :ok
      else
        {:error, :invalid_signature}
      end
    else
      # No secret configured, skip verification (not recommended for production)
      :ok
    end
  end

  @doc """
  Handles user lifecycle create event.
  """
  def handle_user_created(tenant, integration, user_id) do
    Logger.info("Handling user created event for ID: #{user_id}")

    with {:ok, user_data} <- fetch_single_user(integration, user_id),
         {:ok, _action, _workflow} <- EmployeeSync.sync_employee(tenant, user_data, integration) do
      {:ok, %{action: :created, user_id: user_id}}
    end
  end

  @doc """
  Handles user lifecycle activate event.
  """
  def handle_user_activated(tenant, integration, user_id) do
    Logger.info("Handling user activated event for ID: #{user_id}")

    with {:ok, user_data} <- fetch_single_user(integration, user_id),
         {:ok, _action, _workflow} <- EmployeeSync.sync_employee(tenant, user_data, integration) do
      {:ok, %{action: :activated, user_id: user_id}}
    end
  end

  @doc """
  Handles user lifecycle deactivate event.
  """
  def handle_user_deactivated(tenant, integration, user_id) do
    Logger.info("Handling user deactivated event for ID: #{user_id}")

    with {:ok, user_data} <- fetch_single_user(integration, user_id),
         {:ok, _action, _workflow} <- EmployeeSync.sync_employee(tenant, user_data, integration) do
      {:ok, %{action: :deactivated, user_id: user_id}}
    end
  end

  @doc """
  Handles batch user updates from multiple events.
  """
  def handle_batch_events(tenant, integration, events) do
    Logger.info("Handling batch of #{length(events)} events")

    results = Enum.map(events, fn event ->
      case process_single_event(tenant, integration, event) do
        {:ok, result} -> {:ok, result}
        {:error, reason} -> {:error, %{event_id: event["uuid"], error: reason}}
      end
    end)

    successful = Enum.filter(results, &match?({:ok, _}, &1))
    failed = Enum.filter(results, &match?({:error, _}, &1))

    {:ok, %{
      total: length(events),
      successful: length(successful),
      failed: length(failed),
      results: results
    }}
  end

  # Private functions

  defp get_okta_integration(tenant) do
    case Integrations.get_integration_by_provider(tenant, "okta") do
      {:ok, integration} -> {:ok, integration}
      {:error, :not_found} -> {:error, :integration_not_found}
      error -> error
    end
  end

  defp process_event_hook(tenant, integration, %{"data" => %{"events" => events}}) when is_list(events) do
    handle_batch_events(tenant, integration, events)
  end

  defp process_event_hook(_tenant, _integration, payload) do
    Logger.error("Unrecognized Okta event hook payload format: #{inspect(payload)}")
    {:error, :invalid_payload_format}
  end

  defp process_single_event(tenant, integration, %{"eventType" => event_type} = event) do
    # Ignore .initiated events as they often lack complete user info
    # We'll process the completed event instead
    if String.ends_with?(event_type, ".initiated") do
      Logger.info("Ignoring #{event_type} - will process when completed")
      {:ok, %{action: :ignored, event_type: event_type, reason: "initiated_event"}}
    else
      # Extract user ID from target (target is a list, get first element)
      # For some events, target may be nil - try actor as fallback
      user_id =
        event
        |> Map.get("target", [])
        |> List.first()
        |> case do
          nil ->
            # Try to get from actor for events where target is nil
            event
            |> Map.get("actor", %{})
            |> Map.get("id")

          target ->
            Map.get(target, "id")
        end

      if is_nil(user_id) do
        Logger.warning(
          "No user ID found in event (type: #{event_type}). " <>
            "Target: #{inspect(event["target"])}, Actor: #{inspect(event["actor"])}"
        )

        {:error, :no_user_id}
      else
        process_user_event(tenant, integration, event_type, user_id)
      end
    end
  end

  defp process_user_event(tenant, integration, event_type, user_id) do
    case event_type do
        "user.lifecycle.create" ->
          handle_user_created(tenant, integration, user_id)

        "user.lifecycle.activate" ->
          handle_user_activated(tenant, integration, user_id)

        "user.lifecycle.deactivate" ->
          handle_user_deactivated(tenant, integration, user_id)

        "user.lifecycle.suspend" ->
          handle_user_deactivated(tenant, integration, user_id)

        "user.lifecycle.unsuspend" ->
          handle_user_activated(tenant, integration, user_id)

        "user.lifecycle.delete" ->
          handle_user_deactivated(tenant, integration, user_id)

        _ ->
          Logger.warning("Unknown Okta event type: #{event_type}")
          {:ok, %{action: :ignored, event_type: event_type}}
    end
  end

  defp process_single_event(_tenant, _integration, event) do
    Logger.error("Invalid event structure: #{inspect(event)}")
    {:error, :invalid_event_structure}
  end

  defp fetch_single_user(integration, user_id) do
    client = Client.build_client(integration)
    Api.fetch_user(client, user_id)
  end
end