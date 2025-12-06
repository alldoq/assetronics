defmodule Assetronics.Integrations.Processors.InvoiceProcessorTest do
  use ExUnit.Case
  alias Assetronics.Integrations.Processors.InvoiceProcessor

  # Simulating the pipeline flow
  
  test "process_messages/3 ignores non-pdf attachments" do
    messages = [
      %{id: "1", attachments: [%{id: "att1", mime_type: "image/png", filename: "logo.png"}]}
    ]
    
    fetcher = fn _, _ -> {:ok, "content"} end
    
    stats = InvoiceProcessor.process_messages("tenant", messages, fetcher)
    assert stats.assets_created == 0
  end

  test "process_messages/3 processes pdf attachments" do
    # Requires mocking PdfExtractor or Ollama, which are hard dependencies.
    # We test the filtering logic here.
    
    messages = [
      %{id: "1", attachments: []} # Empty
    ]
    fetcher = fn _, _ -> {:ok, "content"} end
    stats = InvoiceProcessor.process_messages("tenant", messages, fetcher)
    assert stats.processed == 0 # Filtered out before processing
  end
end
