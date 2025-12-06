defmodule AssetronicsWeb.AgentJSON do
  alias Assetronics.Assets.Asset

  @doc """
  Renders a single asset.
  """
  def show(%{asset: asset}) do
    %{data: data(asset)}
  end

  defp data(%Asset{} = asset) do
    %{
      id: asset.id,
      asset_tag: asset.asset_tag,
      serial_number: asset.serial_number, 
      hostname: asset.hostname,
      last_checkin_at: asset.last_checkin_at,
      status: asset.status
    }
  end
end
