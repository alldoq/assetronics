defmodule AssetronicsWeb.ReportController do
  use AssetronicsWeb, :controller
  alias Assetronics.Reports

  action_fallback AssetronicsWeb.FallbackController

  def license_reclamation(conn, params) do
    tenant = conn.assigns[:tenant]
    days = Map.get(params, "days", "90") |> String.to_integer()

    report = Reports.license_reclamation(tenant, days)
    json(conn, %{data: report})
  end
end
