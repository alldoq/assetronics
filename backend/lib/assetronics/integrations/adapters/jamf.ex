defmodule Assetronics.Integrations.Adapters.Jamf do
  @moduledoc """
  Integration adapter for Jamf Pro (MDM for Apple devices).
  Uses the Jamf Pro API (v1) with OAuth 2.0 client credentials flow.
  Extracts comprehensive device data including hardware, software, security,
  purchasing, user information, and device images.
  """

  @behaviour Assetronics.Integrations.Adapter

  alias Assetronics.Integrations.Adapters.Jamf.{Api, Auth, ImageHandler, Parsers}
  alias Assetronics.Integrations.Integration
  alias Assetronics.Assets
  require Logger

  @impl true
  def test_connection(%Integration{} = integration) do
    case Auth.get_token(integration) do
      {:ok, _token} -> {:ok, %{success: true, message: "Connected to Jamf Pro"}}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def sync(tenant, %Integration{} = integration) do
    with {:ok, token} <- Auth.get_token(integration) do
      comp_results = sync_resource(tenant, integration, token, :computers)
      mob_results = sync_resource(tenant, integration, token, :mobiles)

      total_synced = comp_results.synced + mob_results.synced
      total_failed = comp_results.failed + mob_results.failed

      {:ok,
       %{
         assets_synced: total_synced,
         failed_count: total_failed,
         details: %{computers: comp_results.synced, mobiles: mob_results.synced}
       }}
    else
      error -> error
    end
  end

  # Sync logic

  defp sync_resource(tenant, integration, token, type, page \\ 0, acc_stats \\ %{synced: 0, failed: 0}) do
    fetch_result =
      case type do
        :computers -> Api.fetch_computers(integration, token, page)
        :mobiles -> Api.fetch_mobile_devices(integration, token, page)
      end

    case fetch_result do
      {:ok, items, total_count} ->
        page_stats =
          Enum.reduce(items, %{synced: 0, failed: 0}, fn item, stats ->
            result =
              case type do
                :computers -> process_computer(tenant, integration, token, item)
                :mobiles -> process_mobile(tenant, integration, token, item)
              end

            case result do
              {:ok, _} -> %{stats | synced: stats.synced + 1}

              {:error, reason} ->
                Logger.warning("Failed to sync #{type} item: #{inspect(reason)}")
                %{stats | failed: stats.failed + 1}
            end
          end)

        new_stats = %{
          synced: acc_stats.synced + page_stats.synced,
          failed: acc_stats.failed + page_stats.failed
        }

        page_size = Api.page_size()

        if (page + 1) * page_size < total_count do
          sync_resource(tenant, integration, token, type, page + 1, new_stats)
        else
          new_stats
        end

      {:error, reason} ->
        Logger.error("Jamf sync failed for #{type} page #{page}: #{inspect(reason)}")
        acc_stats
    end
  end

  defp process_computer(tenant, integration, token, data) do
    attrs = Parsers.parse_computer(data)
    image_url = ImageHandler.fetch_computer_image(integration, token, data["id"])
    attrs = Map.put(attrs, :image_url, image_url)

    Assets.sync_from_mdm(tenant, attrs)
  end

  defp process_mobile(tenant, integration, token, data) do
    attrs = Parsers.parse_mobile_device(data)
    image_url = ImageHandler.fetch_mobile_image(integration, token, data["id"])
    attrs = Map.put(attrs, :image_url, image_url)

    Assets.sync_from_mdm(tenant, attrs)
  end
end
