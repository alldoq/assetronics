defmodule Assetronics.Utils.PdfExtractor do
  @moduledoc """
  Utilities for extracting text from PDF files.
  Supports `pdftotext` (Linux/standard) and `textutil` (macOS).
  """

  require Logger

  def extract_text(pdf_path) do
    cond do
      System.find_executable("pdftotext") ->
        try_pdftotext(pdf_path)
      
      System.find_executable("textutil") ->
        try_textutil(pdf_path)
        
      true ->
        {:error, "No PDF extraction tool found (requires pdftotext or textutil)"}
    end
  end

  defp try_pdftotext(pdf_path) do
    # -layout maintains physical layout which is better for invoices
    case System.cmd("pdftotext", ["-layout", pdf_path, "-"]) do
      {text, 0} -> {:ok, text}
      {error, _code} -> 
        Logger.warning("pdftotext failed: #{inspect(error)}. Trying fallback if available.")
        # Fallback to textutil if on mac
        if System.find_executable("textutil") do
          try_textutil(pdf_path)
        else
          {:error, "pdftotext failed and no fallback available"}
        end
    end
  end

  defp try_textutil(pdf_path) do
    # textutil -convert txt -stdout file.pdf
    case System.cmd("textutil", ["-convert", "txt", "-stdout", pdf_path]) do
      {text, 0} -> {:ok, text}
      {error, _code} -> {:error, "textutil failed: #{inspect(error)}"}
    end
  end
end
