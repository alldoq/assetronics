defmodule AssetronicsWeb.DashboardController do
  @moduledoc """
  Controller for dashboard metrics and analytics.

  Provides role-based dashboard views:
  - Employee dashboard: Personal assets, workflows, and tasks
  - Manager dashboard: Team overview and metrics
  - Admin dashboard: System-wide operational data
  """

  use AssetronicsWeb, :controller

  alias Assetronics.Dashboard

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  Gets dashboard data based on user role.

  Automatically determines which dashboard to show based on the authenticated user's role:
  - employee: Shows personal assets and workflows
  - manager: Shows team overview and asset distribution
  - admin: Shows system-wide metrics and integration health
  - super_admin: Shows multi-tenant system metrics
  """
  def index(conn, _params) do
    require Logger

    tenant = conn.assigns[:tenant]
    user = conn.assigns[:current_user]

    Logger.info("[DashboardController] Loading dashboard for user #{user.id} (role: #{user.role}) in tenant #{tenant}")

    try do
      data = case user.role do
        "employee" ->
          if user.employee_id do
            Dashboard.get_employee_dashboard(tenant, user.employee_id)
          else
            raise "User does not have an associated employee record"
          end

        "manager" ->
          if user.employee_id do
            Dashboard.get_manager_dashboard(tenant, user.employee_id)
          else
            raise "User does not have an associated employee record"
          end

        "admin" ->
          Dashboard.get_admin_dashboard(tenant, user.id)

        "super_admin" ->
          Dashboard.get_admin_dashboard(tenant, user.id)

        _ ->
          if user.employee_id do
            Dashboard.get_employee_dashboard(tenant, user.employee_id)
          else
            raise "User does not have an associated employee record"
          end
      end

      Logger.info("[DashboardController] Successfully loaded dashboard for user #{user.id}")
      render(conn, :show, dashboard: data, role: user.role)
    rescue
      e in Ecto.NoResultsError ->
        Logger.error("[DashboardController] No results found for user #{user.id}: #{Exception.message(e)}")
        conn
        |> put_status(:not_found)
        |> json(%{error: %{message: "Employee record not found for user"}})

      e in RuntimeError ->
        if String.contains?(Exception.message(e), "employee record") do
          Logger.error("[DashboardController] User #{user.id} does not have an associated employee record")
          conn
          |> put_status(:not_found)
          |> json(%{error: %{message: "User does not have an associated employee record"}})
        else
          Logger.error("[DashboardController] Runtime error loading dashboard for user #{user.id}: #{Exception.message(e)}\n#{Exception.format_stacktrace(__STACKTRACE__)}")
          conn
          |> put_status(:internal_server_error)
          |> json(%{error: %{message: "Failed to load dashboard"}})
        end

      e ->
        Logger.error("[DashboardController] Error loading dashboard for user #{user.id}: #{Exception.message(e)}\n#{Exception.format_stacktrace(__STACKTRACE__)}")
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: %{message: "Failed to load dashboard"}})
    end
  end
end
