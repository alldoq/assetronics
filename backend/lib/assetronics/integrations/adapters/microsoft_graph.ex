defmodule Assetronics.Integrations.Adapters.MicrosoftGraph do
  @moduledoc """
  Integration adapter for Microsoft Graph (Mail).
  
  Uses Client Credentials Flow to access specific mailboxes.
  """
  
  @behaviour Assetronics.Integrations.Adapter

  alias Assetronics.Integrations.Integration
  require Logger

  @impl true
  def test_connection(%Integration{} = integration) do
    target_user = integration.auth_config["target_email"]
    
    if is_nil(target_user) do
      {:error, "Target email is required in configuration"}
    else
      case get_access_token(integration) do
        {:ok, token} ->
          # Test by fetching user profile
          url = "https://graph.microsoft.com/v1.0/users/#{target_user}"
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

    Logger.info("Starting Microsoft Graph sync for tenant: #{tenant}, integration: #{integration.id}")

    case fetch_unprocessed_emails(integration, limit: 10) do
      {:ok, messages_data} when is_list(messages_data) ->
        Logger.info("Found #{length(messages_data)} unprocessed Microsoft Graph messages")

        if length(messages_data) == 0 do
          {:ok, %{processed: 0, created: 0, errors: 0}}
        else
          # 2. Standardize structure and fetch attachments
          messages = Enum.map(messages_data, fn msg ->
            if msg["hasAttachments"] do
              case get_message_attachments(integration, msg["id"]) do
                {:ok, %{status: 200, body: %{"value" => attachments}}} when is_list(attachments) ->
                  # Filter for PDF attachments only
                  pdf_attachments = Enum.filter(attachments, fn att ->
                    String.contains?(att["contentType"] || "", "pdf") ||
                      String.ends_with?(String.downcase(att["name"] || ""), ".pdf")
                  end)

                  if length(pdf_attachments) > 0 do
                    %{
                      id: msg["id"],
                      attachments: Enum.map(pdf_attachments, fn att ->
                        %{
                          id: att["id"],
                          filename: att["name"],
                          mime_type: att["contentType"]
                        }
                      end)
                    }
                  else
                    Logger.debug("Microsoft Graph message #{msg["id"]} has no PDF attachments")
                    nil
                  end

                {:ok, %{status: status, body: body}} ->
                  Logger.warning("Failed to fetch attachments for message #{msg["id"]}: #{status} - #{inspect(body)}")
                  nil

                {:error, reason} ->
                  Logger.error("Error fetching attachments for message #{msg["id"]}: #{inspect(reason)}")
                  nil
              end
            else
              Logger.debug("Microsoft Graph message #{msg["id"]} has no attachments")
              nil
            end
          end)
          |> Enum.reject(&is_nil/1)

          Logger.info("Processing #{length(messages)} Microsoft Graph messages with PDF attachments")

          # 3. Define fetcher callback
          fetcher = fn message_id, attachment_id ->
            case get_attachment(integration, message_id, attachment_id) do
              {:ok, %{status: 200, body: body}} when is_map(body) ->
                content_bytes = body["contentBytes"]
                if content_bytes do
                  {:ok, Base.decode64!(content_bytes)}
                else
                  Logger.error("No contentBytes in attachment #{attachment_id} for message #{message_id}")
                  {:error, "No content in attachment"}
                end

              {:ok, %{status: status, body: body}} ->
                Logger.error("Failed to fetch Microsoft Graph attachment #{attachment_id}: #{status} - #{inspect(body)}")
                {:error, "Failed to fetch attachment: #{status}"}

              {:error, reason} ->
                Logger.error("Error fetching Microsoft Graph attachment #{attachment_id}: #{inspect(reason)}")
                {:error, reason}
            end
          end

          # 4. Process messages and extract invoices
          stats = InvoiceProcessor.process_messages(tenant, messages, fetcher)
          Logger.info("Microsoft Graph processing complete: #{inspect(stats)}")

          # 5. Mark ALL attempted messages as processed
          processed_ids = Enum.map(messages, & &1.id)
          mark_as_processed(integration, processed_ids)

          {:ok, stats}
        end

      {:error, reason} = error ->
        Logger.error("Failed to fetch Microsoft Graph messages: #{inspect(reason)}")
        error
    end
  rescue
    exception ->
      Logger.error("Exception during Microsoft Graph sync: #{inspect(exception)}")
      Logger.error("Stacktrace: #{Exception.format_stacktrace(__STACKTRACE__)}")
      {:error, "Microsoft Graph sync failed: #{Exception.message(exception)}"}
  end
  
  defp mark_as_processed(integration, message_ids) when is_list(message_ids) and length(message_ids) > 0 do
    target_user = integration.auth_config["target_email"]

    Logger.info("Marking #{length(message_ids)} Microsoft Graph messages as processed for #{target_user}")

    with {:ok, token} <- get_access_token(integration) do
      # Microsoft Graph doesn't have batch modify like Gmail
      # We'll update each message individually (could be parallelized with Task.async_stream)
      results = Enum.map(message_ids, fn id ->
        url = "https://graph.microsoft.com/v1.0/users/#{target_user}/messages/#{id}"

        # Mark as read and add a custom category
        body = %{
          isRead: true,
          categories: ["Assetronics Processed"]
        }

        case Req.patch(url, headers: authorization_headers(token), json: body) do
          {:ok, %{status: status}} when status in 200..299 ->
            {:ok, id}

          {:ok, %{status: status, body: body}} ->
            Logger.warning("Failed to mark message #{id} as processed: #{status} - #{inspect(body)}")
            {:error, id}

          {:error, reason} ->
            Logger.error("Error marking message #{id} as processed: #{inspect(reason)}")
            {:error, id}
        end
      end)

      successful = Enum.count(results, fn {status, _} -> status == :ok end)
      Logger.info("Successfully marked #{successful}/#{length(message_ids)} Microsoft Graph messages as processed")

      {:ok, %{marked: successful, failed: length(message_ids) - successful}}
    else
      {:error, reason} ->
        Logger.error("Failed to get access token for marking messages: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp mark_as_processed(_integration, []), do: {:ok, %{marked: 0, failed: 0}}

  # Public API for Workers
  def fetch_unprocessed_emails(integration, opts \\ []) do
    target_user = integration.auth_config["target_email"]
    limit = Keyword.get(opts, :limit, 10)
    # Filter for unprocessed emails with attachments
    # OData filter query excludes already categorized messages
    filter = "hasAttachments eq true and isRead eq false and not categories/any(c: c eq 'Assetronics Processed')" 

    with {:ok, token} <- get_access_token(integration) do
      url = "https://graph.microsoft.com/v1.0/users/#{target_user}/messages"
      params = ["$top": limit, "$filter": filter, "$select": "id,subject,receivedDateTime,hasAttachments"]
      
      case Req.get(url, headers: authorization_headers(token), params: params) do
        {:ok, %{status: 200, body: body}} ->
          messages = Map.get(body, "value", [])
          {:ok, messages}
        error -> error
      end
    end
  end

  def get_message_attachments(integration, message_id) do
    target_user = integration.auth_config["target_email"]
    with {:ok, token} <- get_access_token(integration) do
      url = "https://graph.microsoft.com/v1.0/users/#{target_user}/messages/#{message_id}/attachments"
      Req.get(url, headers: authorization_headers(token))
    end
  end
  
  def get_attachment(integration, message_id, attachment_id) do
    target_user = integration.auth_config["target_email"]
    with {:ok, token} <- get_access_token(integration) do
      url = "https://graph.microsoft.com/v1.0/users/#{target_user}/messages/#{message_id}/attachments/#{attachment_id}"
      Req.get(url, headers: authorization_headers(token))
    end
  end

  defp get_access_token(integration) do
    client_id = integration.auth_config["client_id"]
    client_secret = integration.auth_config["client_secret"]
    tenant_id = integration.auth_config["tenant_id"]

    if !client_id or !client_secret or !tenant_id do
      {:error, "Missing Microsoft credentials"}
    else
      url = "https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token"
      body = {:form, [
        client_id: client_id,
        scope: "https://graph.microsoft.com/.default",
        client_secret: client_secret,
        grant_type: "client_credentials"
      ]}

      case Req.post(url, body) do
        {:ok, %{status: 200, body: %{"access_token" => token}}} -> {:ok, token}
        {:ok, %{body: body}} -> {:error, "Token request failed: #{inspect(body)}"}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp authorization_headers(token) do
    [Authorization: "Bearer #{token}", Accept: "application/json"]
  end
end
