defmodule Assetronics.Labels.LabelGenerator do
  @moduledoc """
  Generates printable labels and QR codes for assets.

  QR codes encode a URL to view the asset, allowing quick scanning
  and access to asset details.
  """

  @doc """
  Generates a QR code for an asset.

  Returns a base64-encoded SVG string containing the QR code.
  The QR code encodes the URL to view the asset.

  ## Examples

      iex> generate_qr_code("acme", "asset-id-123")
      {:ok, "data:image/svg+xml;base64,PHN2ZyB4..."}

  """
  def generate_qr_code(_tenant, asset_id) do
    # Construct the URL that the QR code will point to
    # In production, this should use the actual frontend URL from config
    frontend_url = System.get_env("FRONTEND_URL") || "http://localhost:5173"
    asset_url = "#{frontend_url}/assets/#{asset_id}"

    try do
      # Generate QR code - EQRCode.encode returns the matrix directly
      qr_code = EQRCode.encode(asset_url)

      # Generate SVG
      svg = qr_code |> EQRCode.svg(width: 200)

      # Encode as base64 data URI
      base64 = Base.encode64(svg)
      data_uri = "data:image/svg+xml;base64,#{base64}"

      {:ok, data_uri}
    rescue
      error ->
        {:error, "Failed to generate QR code: #{inspect(error)}"}
    end
  end

  @doc """
  Generates label data for an asset.

  Returns a map containing all the information needed to print a label,
  including the QR code.

  ## Examples

      iex> generate_label(asset)
      %{
        qr_code: "data:image/svg+xml;base64,...",
        asset_tag: "ASSET-001",
        name: "MacBook Pro",
        serial_number: "C02ABC123",
        make: "Apple",
        model: "MacBook Pro 16\"",
        category: "laptop"
      }

  """
  def generate_label(tenant, asset) do
    with {:ok, qr_code} <- generate_qr_code(tenant, asset.id) do
      {:ok, %{
        qr_code: qr_code,
        asset_tag: asset.asset_tag,
        name: asset.name,
        serial_number: asset.serial_number,
        make: asset.make,
        model: asset.model,
        category: asset.category,
        asset_id: asset.id
      }}
    end
  end

  @doc """
  Generates labels for multiple assets.

  Useful for batch printing labels.
  """
  def generate_batch_labels(tenant, assets) when is_list(assets) do
    results = Enum.map(assets, fn asset ->
      case generate_label(tenant, asset) do
        {:ok, label_data} -> {:ok, label_data}
        {:error, reason} -> {:error, %{asset_id: asset.id, reason: reason}}
      end
    end)

    successful = Enum.filter(results, &match?({:ok, _}, &1)) |> Enum.map(fn {:ok, data} -> data end)
    failed = Enum.filter(results, &match?({:error, _}, &1)) |> Enum.map(fn {:error, data} -> data end)

    {:ok, %{
      successful: successful,
      failed: failed,
      total: length(assets),
      success_count: length(successful),
      failure_count: length(failed)
    }}
  end
end
