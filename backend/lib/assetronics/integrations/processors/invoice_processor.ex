defmodule Assetronics.Integrations.Processors.InvoiceProcessor do
  @moduledoc """
  Common logic for processing invoice emails from Gmail/Microsoft.
  """
  
  alias Assetronics.AI.Ollama
  alias Assetronics.Utils.PdfExtractor
  alias Assetronics.Assets
  require Logger

  def process_messages(tenant, messages, fetch_attachment_fn) do
    # messages is a list of message summaries (id, subject, etc.)
    # fetch_attachment_fn is a function (message_id, attachment_id) -> {:ok, binary_content}
    
    results = Enum.map(messages, fn message ->
      process_single_message(tenant, message, fetch_attachment_fn)
    end)
    
    # Aggregate stats
    Enum.reduce(results, %{processed: 0, assets_created: 0, errors: []}, fn res, acc ->
      case res do
        {:ok, count} -> 
          %{acc | processed: acc.processed + 1, assets_created: acc.assets_created + count}
        {:error, reason} -> 
          %{acc | errors: [reason | acc.errors]}
        :ignore -> acc
      end
    end)
  end

  defp process_single_message(tenant, message, fetch_attachment_fn) do
    # 1. Identify attachments
    # This part depends on the message structure passed from the adapter.
    # We expect a unified structure or we handle specific provider structs.
    # For now, let's assume the adapter passes a map with :id and :attachments list
    
    attachments = message[:attachments] || []
    
    if Enum.empty?(attachments) do
      :ignore
    else
      # 2. Process each PDF attachment
      assets_count = Enum.reduce(attachments, 0, fn attachment, count ->
        if is_pdf?(attachment) do
          case fetch_attachment_fn.(message[:id], attachment[:id]) do
            {:ok, content} ->
              case process_pdf_content(content) do
                {:ok, data} -> 
                  case Assetronics.Assets.create_from_invoice(tenant, data) do
                    {:ok, count_created} ->
                      Logger.info("Created/Updated #{count_created} assets from invoice")
                      count + count_created
                    error ->
                      Logger.error("Failed to create assets: #{inspect(error)}")
                      count
                  end
                {:error, reason} ->
                  Logger.warning("Failed to process PDF: #{inspect(reason)}")
                  count
              end
            _ -> count
          end
        else
          count
        end
      end)
      
      {:ok, assets_count}
    end
  end

  defp is_pdf?(attachment) do
    # Check mimeType or filename
    mime = attachment[:mime_type] || ""
    name = attachment[:filename] || ""
    String.contains?(mime, "pdf") || String.ends_with?(String.downcase(name), ".pdf")
  end

  defp process_pdf_content(content) do
    # 1. Save to temp file
    temp_path = Path.join(System.tmp_dir!(), "invoice_#{UUID.uuid4()}.pdf")
    File.write!(temp_path, content)
    
    try do
      # 2. Extract Text
      with {:ok, text} <- PdfExtractor.extract_text(temp_path),
           # 3. Send to Ollama
           {:ok, data} <- Ollama.extract_invoice_data(text) do
        {:ok, data}
      else
        error -> error
      end
    after
      File.rm(temp_path)
    end
  end
end
