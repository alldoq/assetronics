defmodule Assetronics.AI.Ollama do
  require Logger

  @default_url "http://localhost:11434"
  @default_model "llama3" # Or "mistral", or "llava" for vision

  def generate(prompt, opts \\ []) do
    url = Keyword.get(opts, :url, Application.get_env(:assetronics, :ollama_url, @default_url))
    model = Keyword.get(opts, :model, Application.get_env(:assetronics, :ollama_model, @default_model))
    body = %{  model: model,  prompt: prompt,  stream: false,  format: "json" }

    case Req.post("#{url}/api/generate", json: body, receive_timeout: 60_000) do
      {:ok, %{status: 200, body: %{"response" => response}}} ->  {:ok, response}
      {:ok, %{status: status, body: body}} ->  {:error, "Ollama API error: #{status} - #{inspect(body)}"}
      {:error, reason} ->  {:error, "Connection failed: #{inspect(reason)}"}
    end
  end

  def extract_invoice_data(invoice_text) do
    prompt = """
    You are an expert data extraction assistant. Analyze the following invoice text and extract the asset information.

    Return ONLY a JSON object with the following structure:
    {
      "assets": [
        {
          "description": "Item description",
          "quantity": 1,
          "unit_price": 1000.00,
          "total_price": 1000.00,
          "serial_number": "extracted serial if present, else null",
          "manufacturer": "Dell/Apple/etc",
          "model": "Model name"
        }
      ],
      "invoice_number": "INV-123",
      "vendor": "Vendor Name",
      "date": "YYYY-MM-DD",
      "currency": "USD"
    }

    Invoice Text:
    #{invoice_text}
    """

    case generate(prompt) do
      {:ok, json_string} ->
        case Jason.decode(json_string) do
          {:ok, data} -> {:ok, data}
          {:error, _} ->
            clean_json = json_string  |> String.replace("```json", "")  |> String.replace("```", "") |> String.trim()
            Jason.decode(clean_json)
        end
      error -> error
    end
  end
end
