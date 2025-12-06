defmodule Assetronics.Integrations.Adapters.Gmail do
  @moduledoc """
  Integration adapter for Gmail.
  
  Uses Service Account with Domain-Wide Delegation to access specific mailboxes.
  """
  
  @behaviour Assetronics.Integrations.Adapter

  alias Assetronics.Integrations.Integration
  require Logger

  @required_scopes ["https://www.googleapis.com/auth/gmail.readonly"]

  @impl true
  def test_connection(%Integration{} = integration) do
    target_user = integration.auth_config["target_email"]
    
    if is_nil(target_user) do
      {:error, "Target email is required in configuration"}
    else
      case get_access_token(integration, target_user) do
        {:ok, token} ->
          # Test by fetching profile
          url = "https://gmail.googleapis.com/gmail/v1/users/#{target_user}/profile"
          case Req.get(url, headers: authorization_headers(token)) do
            {:ok, %{status: 200}} -> {:ok, %{success: true, message: "Connected to #{target_user}"}}
            {:ok, %{status: status, body: body}} -> {:error, "Connection failed: #{status} - #{inspect(body)}"}
            {:error, reason} -> {:error, reason}
          end
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @impl true
  def sync(tenant, %Integration{} = integration) do
    alias Assetronics.Integrations.Processors.InvoiceProcessor

    Logger.info("Starting Gmail sync for tenant: #{tenant}, integration: #{integration.id}")

    # Query for unprocessed messages with attachments
    # Excludes messages already labeled as "Assetronics/Processed"
    query = "has:attachment -label:Assetronics/Processed"

    case fetch_unprocessed_emails(integration, limit: 10, query: query) do
      {:ok, message_summaries} when is_list(message_summaries) ->
        Logger.info("Found #{length(message_summaries)} unprocessed Gmail messages")

        if length(message_summaries) == 0 do
          {:ok, %{processed: 0, created: 0, errors: 0}}
        else
          # 2. Fetch full details for each to get attachments info
          messages = Enum.map(message_summaries, fn summary ->
            case get_message_details(integration, summary["id"]) do
              {:ok, %{status: 200, body: body}} ->
                attachments = extract_attachments_meta(body)
                if length(attachments) > 0 do
                  %{
                    id: body["id"],
                    attachments: attachments
                  }
                else
                  Logger.debug("Gmail message #{summary["id"]} has no valid attachments")
                  nil
                end

              {:ok, %{status: status, body: body}} ->
                Logger.warning("Failed to fetch Gmail message #{summary["id"]}: #{status} - #{inspect(body)}")
                nil

              {:error, reason} ->
                Logger.error("Error fetching Gmail message #{summary["id"]}: #{inspect(reason)}")
                nil
            end
          end)
          |> Enum.reject(&is_nil/1)

          Logger.info("Processing #{length(messages)} Gmail messages with attachments")

          # 3. Define fetcher callback
          fetcher = fn message_id, attachment_id ->
            case get_attachment(integration, message_id, attachment_id) do
              {:ok, %{status: 200, body: %{"data" => data}}} ->
                # Gmail uses Base64Url encoding
                {:ok, Base.url_decode64!(data, padding: false)}

              {:ok, %{status: status, body: body}} ->
                Logger.error("Failed to fetch Gmail attachment #{attachment_id}: #{status} - #{inspect(body)}")
                {:error, "Failed to fetch attachment: #{status}"}

              {:error, reason} ->
                Logger.error("Error fetching Gmail attachment #{attachment_id}: #{inspect(reason)}")
                {:error, reason}
            end
          end

          # 4. Process messages and extract invoices
          stats = InvoiceProcessor.process_messages(tenant, messages, fetcher)
          Logger.info("Gmail processing complete: #{inspect(stats)}")

          # 5. Mark ALL attempted messages as processed to avoid re-processing
          # This includes failed ones to prevent infinite retry loops on bad PDFs
          processed_ids = Enum.map(messages, & &1.id)
          mark_as_processed(integration, processed_ids)

          {:ok, stats}
        end

      {:error, reason} = error ->
        Logger.error("Failed to fetch Gmail messages: #{inspect(reason)}")
        error
    end
  rescue
    exception ->
      Logger.error("Exception during Gmail sync: #{inspect(exception)}")
      Logger.error("Stacktrace: #{Exception.format_stacktrace(__STACKTRACE__)}")
      {:error, "Gmail sync failed: #{Exception.message(exception)}"}
  end
  
  defp mark_as_processed(integration, message_ids) when is_list(message_ids) and length(message_ids) > 0 do
    target_user = integration.auth_config["target_email"]

    Logger.info("Marking #{length(message_ids)} Gmail messages as processed for #{target_user}")

    with {:ok, token} <- get_access_token(integration, target_user),
         {:ok, label_id} <- get_or_create_processed_label(integration, token, target_user) do

      # Batch modify to add our custom label
      url = "https://gmail.googleapis.com/gmail/v1/users/#{target_user}/messages/batchModify"

      body = %{
        "ids" => message_ids,
        "addLabelIds" => [label_id]
      }

      case Req.post(url, headers: authorization_headers(token), json: body) do
        {:ok, %{status: 204}} ->
          Logger.info("Successfully marked #{length(message_ids)} Gmail messages as processed")
          {:ok, %{marked: length(message_ids)}}

        {:ok, %{status: status, body: body}} ->
          Logger.error("Failed to mark Gmail messages as processed: #{status} - #{inspect(body)}")
          {:error, "Failed to mark messages: #{status}"}

        {:error, reason} ->
          Logger.error("Error marking Gmail messages as processed: #{inspect(reason)}")
          {:error, reason}
      end
    else
      {:error, reason} ->
        Logger.error("Failed to mark Gmail messages as processed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp mark_as_processed(_integration, []), do: {:ok, %{marked: 0}}

  defp get_or_create_processed_label(integration, token, target_user) do
    label_name = "Assetronics/Processed"

    # Try to find existing label
    case find_label_by_name(integration, token, target_user, label_name) do
      {:ok, label_id} ->
        {:ok, label_id}

      {:error, :not_found} ->
        # Create the label
        Logger.info("Creating Gmail label '#{label_name}' for #{target_user}")
        create_label(integration, token, target_user, label_name)

      error ->
        error
    end
  end

  defp find_label_by_name(_integration, token, target_user, label_name) do
    url = "https://gmail.googleapis.com/gmail/v1/users/#{target_user}/labels"

    case Req.get(url, headers: authorization_headers(token)) do
      {:ok, %{status: 200, body: %{"labels" => labels}}} ->
        case Enum.find(labels, fn label -> label["name"] == label_name end) do
          %{"id" => id} -> {:ok, id}
          nil -> {:error, :not_found}
        end

      {:ok, %{status: status, body: body}} ->
        Logger.error("Failed to fetch Gmail labels: #{status} - #{inspect(body)}")
        {:error, "Failed to fetch labels: #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp create_label(_integration, token, target_user, label_name) do
    url = "https://gmail.googleapis.com/gmail/v1/users/#{target_user}/labels"

    body = %{
      "name" => label_name,
      "labelListVisibility" => "labelShow",
      "messageListVisibility" => "show"
    }

    case Req.post(url, headers: authorization_headers(token), json: body) do
      {:ok, %{status: 200, body: %{"id" => id}}} ->
        Logger.info("Created Gmail label '#{label_name}' with ID: #{id}")
        {:ok, id}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Failed to create Gmail label: #{status} - #{inspect(body)}")
        {:error, "Failed to create label: #{status}"}

      {:error, reason} ->
        Logger.error("Error creating Gmail label: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp extract_attachments_meta(message_body) do
    payload = message_body["payload"]
    parts = payload["parts"] || []
    find_attachments(parts)
  end
  
  defp find_attachments(parts) do
    Enum.flat_map(parts, fn part ->
      if part["filename"] && part["filename"] != "" && part["body"]["attachmentId"] do
        [%{
          id: part["body"]["attachmentId"],
          filename: part["filename"],
          mime_type: part["mimeType"]
        }]
      else
        find_attachments(part["parts"] || [])
      end
    end)
  end

  # Public API for Workers to use
  def fetch_unprocessed_emails(integration, opts \\ []) do
    target_user = integration.auth_config["target_email"]
    limit = Keyword.get(opts, :limit, 10)
    query = Keyword.get(opts, :query, "has:attachment label:INBOX -label:processed") # Example query

    with {:ok, token} <- get_access_token(integration, target_user) do
      url = "https://gmail.googleapis.com/gmail/v1/users/#{target_user}/messages"
      params = [q: query, maxResults: limit]
      
      case Req.get(url, headers: authorization_headers(token), params: params) do
        {:ok, %{status: 200, body: body}} ->
          messages = Map.get(body, "messages", [])
          {:ok, messages}
        error -> error
      end
    end
  end

  def get_message_details(integration, message_id) do
    target_user = integration.auth_config["target_email"]
    with {:ok, token} <- get_access_token(integration, target_user) do
      url = "https://gmail.googleapis.com/gmail/v1/users/#{target_user}/messages/#{message_id}"
      Req.get(url, headers: authorization_headers(token))
    end
  end
  
  def get_attachment(integration, message_id, attachment_id) do
    target_user = integration.auth_config["target_email"]
    with {:ok, token} <- get_access_token(integration, target_user) do
      url = "https://gmail.googleapis.com/gmail/v1/users/#{target_user}/messages/#{message_id}/attachments/#{attachment_id}"
      Req.get(url, headers: authorization_headers(token))
    end
  end

  defp get_access_token(integration, sub) do
    case Jason.decode(integration.auth_config["service_account_json"] || "{}") do
      {:ok, credentials} ->
        # We must use "sub" to impersonate the target user
        source = {:service_account, credentials, scopes: @required_scopes, sub: sub}
        
        case Goth.Token.fetch(source) do
          {:ok, token} -> {:ok, token.token}
          error -> error
        end
      _ -> {:error, "Invalid service account JSON"}
    end
  end

  defp authorization_headers(token) do
    [Authorization: "Bearer #{token}", Accept: "application/json"]
  end
end
