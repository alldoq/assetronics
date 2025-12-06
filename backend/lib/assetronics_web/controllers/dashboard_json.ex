defmodule AssetronicsWeb.DashboardJSON do
  @moduledoc """
  JSON rendering for Dashboard resources.
  """

  @doc """
  Renders dashboard data.

  The dashboard structure varies by role:
  - employee: my_assets, my_workflows, recent_activity, stats
  - manager: team_overview, asset_distribution, workflow_status, key_metrics
  - admin: asset_inventory, workflow_metrics, integration_health, employee_status, recent_activity, alerts
  """
  def show(%{dashboard: dashboard, role: role}) do
    %{
      data: dashboard,
      role: role
    }
  end
end
