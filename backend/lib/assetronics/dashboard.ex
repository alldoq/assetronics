defmodule Assetronics.Dashboard do
  @moduledoc """
  Dashboard metrics and analytics for user-facing dashboards.

  Provides role-specific dashboard data:
  - Employee dashboard: My assets, workflows, and tasks
  - Manager dashboard: Team overview, asset distribution, workflow status
  - Admin dashboard: System-wide metrics, integration health, alerts
  - Super admin dashboard: Multi-tenant system metrics
  """

  import Ecto.Query
  alias Assetronics.Repo
  alias Assetronics.Employees
  alias Assetronics.Integrations
  alias Assetronics.Assets.Asset
  alias Assetronics.Workflows.Workflow
  alias Assetronics.Employees.Employee
  alias Assetronics.Transactions.Transaction
  alias Assetronics.Dashboard.Cache
  alias Triplex

  require Logger

  # ============================================================================
  # Employee Dashboard
  # ============================================================================

  @doc """
  Gets dashboard data for an employee.

  Returns:
  - My assets (currently assigned)
  - My workflows (active)
  - Recent activity
  - Quick stats

  Results are cached for 5 minutes.
  """
  def get_employee_dashboard(tenant, employee_id) do
    Cache.get_or_compute("#{tenant}:employee:#{employee_id}", fn ->
      fetch_employee_dashboard(tenant, employee_id)
    end)
  end

  defp fetch_employee_dashboard(tenant, employee_id) do
    Logger.info("[Dashboard] Fetching employee dashboard for employee #{employee_id} in tenant #{tenant}")

    employee = Employees.get_employee!(tenant, employee_id)
    Logger.debug("[Dashboard] Found employee: #{employee.first_name} #{employee.last_name}")

    Logger.debug("[Dashboard] Fetching employee assets...")
    my_assets = get_employee_assets(tenant, employee_id)
    Logger.debug("[Dashboard] Found #{length(my_assets)} assets")

    Logger.debug("[Dashboard] Fetching employee workflows...")
    my_workflows = get_employee_workflows(tenant, employee_id)
    Logger.debug("[Dashboard] Found #{length(my_workflows)} workflows")

    Logger.debug("[Dashboard] Fetching employee recent activity...")
    recent_activity = get_employee_recent_activity(tenant, employee_id)
    Logger.debug("[Dashboard] Found #{length(recent_activity)} activities")

    Logger.debug("[Dashboard] Fetching employee stats...")
    stats = get_employee_stats(tenant, employee_id)
    Logger.debug("[Dashboard] Stats: #{inspect(stats)}")

    %{
      my_assets: my_assets,
      my_workflows: my_workflows,
      recent_activity: recent_activity,
      stats: stats,
      employee: %{
        id: employee.id,
        name: "#{employee.first_name} #{employee.last_name}",
        email: employee.email,
        department: employee.department,
        job_title: employee.job_title
      }
    }
  end

  defp get_employee_assets(tenant, employee_id) do
    query =
      from a in Asset,
        where: a.employee_id == ^employee_id,
        where: a.status == "assigned",
        order_by: [desc: a.assigned_at]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
    |> Enum.map(fn asset ->
      %{
        id: asset.id,
        name: asset.name,
        asset_tag: asset.asset_tag,
        serial_number: asset.serial_number,
        category: asset.category,
        assigned_at: asset.assigned_at,
        expected_return_date: asset.expected_return_date,
        assignment_type: asset.assignment_type
      }
    end)
  end

  defp get_employee_workflows(tenant, employee_id) do
    query =
      from w in Workflow,
        where: w.employee_id == ^employee_id,
        where: w.status in ["pending", "in_progress"],
        order_by: [asc: w.due_date]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
    |> Enum.map(fn workflow ->
      total_steps = length(workflow.steps || [])
      completed_steps = Enum.count(workflow.steps || [], fn step -> Map.get(step, "completed", false) end)
      progress = if total_steps > 0, do: round(completed_steps / total_steps * 100), else: 0

      %{
        id: workflow.id,
        title: workflow.title,
        workflow_type: workflow.workflow_type,
        status: workflow.status,
        due_date: workflow.due_date,
        current_step: workflow.current_step,
        total_steps: total_steps,
        progress: progress,
        is_overdue: workflow.due_date && Date.compare(workflow.due_date, Date.utc_today()) == :lt
      }
    end)
  end

  defp get_employee_recent_activity(tenant, employee_id) do
    query =
      from t in Transaction,
        left_join: a in assoc(t, :asset),
        where: t.employee_id == ^employee_id or t.to_employee_id == ^employee_id,
        order_by: [desc: t.performed_at],
        limit: 10,
        select: %{
          id: t.id,
          type: t.transaction_type,
          description: t.description,
          performed_at: t.performed_at,
          asset_name: a.name
        }

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  defp get_employee_stats(tenant, employee_id) do
    asset_count_query =
      from a in Asset,
        where: a.employee_id == ^employee_id,
        where: a.status == "assigned",
        select: count(a.id)

    workflow_count_query =
      from w in Workflow,
        where: w.employee_id == ^employee_id,
        where: w.status in ["pending", "in_progress"],
        select: count(w.id)

    pending_tasks_query =
      from w in Workflow,
        where: w.employee_id == ^employee_id,
        where: w.status in ["pending", "in_progress"],
        where: not is_nil(w.due_date),
        select: count(w.id)

    %{
      total_assets: Repo.one(asset_count_query, prefix: Triplex.to_prefix(tenant)) || 0,
      active_workflows: Repo.one(workflow_count_query, prefix: Triplex.to_prefix(tenant)) || 0,
      pending_tasks: Repo.one(pending_tasks_query, prefix: Triplex.to_prefix(tenant)) || 0
    }
  end

  # ============================================================================
  # Manager Dashboard
  # ============================================================================

  @doc """
  Gets dashboard data for a manager.

  Returns:
  - Team overview
  - Asset distribution
  - Workflow status
  - Key metrics

  Results are cached for 5 minutes.
  """
  def get_manager_dashboard(tenant, manager_id) do
    Cache.get_or_compute("#{tenant}:manager:#{manager_id}", fn ->
      fetch_manager_dashboard(tenant, manager_id)
    end)
  end

  defp fetch_manager_dashboard(tenant, manager_id) do
    # For now, we'll get all employees in the same department as the manager
    # In a real system, you'd have a manager_id field on employees
    manager = Employees.get_employee!(tenant, manager_id)

    %{
      team_overview: get_team_overview(tenant, manager.department),
      asset_distribution: get_team_asset_distribution(tenant, manager.department),
      workflow_status: get_team_workflow_status(tenant, manager.department),
      key_metrics: get_team_key_metrics(tenant, manager.department),
      manager: %{
        id: manager.id,
        name: "#{manager.first_name} #{manager.last_name}",
        department: manager.department
      }
    }
  end

  defp get_team_overview(tenant, department) do
    team_query =
      from e in Employee,
        where: e.department == ^department,
        where: e.employment_status == "active",
        select: count(e.id)

    assets_query =
      from a in Asset,
        join: e in Employee,
        on: a.employee_id == e.id,
        where: e.department == ^department,
        where: a.status == "assigned",
        select: count(a.id)

    workflows_query =
      from w in Workflow,
        join: e in Employee,
        on: w.employee_id == e.id,
        where: e.department == ^department,
        where: w.status in ["pending", "in_progress"],
        select: count(w.id)

    %{
      team_size: Repo.one(team_query, prefix: Triplex.to_prefix(tenant)) || 0,
      total_assets: Repo.one(assets_query, prefix: Triplex.to_prefix(tenant)) || 0,
      active_workflows: Repo.one(workflows_query, prefix: Triplex.to_prefix(tenant)) || 0
    }
  end

  defp get_team_asset_distribution(tenant, department) do
    query =
      from a in Asset,
        join: e in Employee,
        on: a.employee_id == e.id,
        where: e.department == ^department,
        where: a.status == "assigned",
        group_by: a.category,
        select: {a.category, count(a.id)}

    results = Repo.all(query, prefix: Triplex.to_prefix(tenant))

    Enum.map(results, fn {category, count} ->
      %{category: category || "Uncategorized", count: count}
    end)
  end

  defp get_team_workflow_status(tenant, department) do
    query =
      from w in Workflow,
        join: e in Employee,
        on: w.employee_id == e.id,
        where: e.department == ^department,
        where: w.status in ["pending", "in_progress"],
        group_by: w.workflow_type,
        select: {w.workflow_type, count(w.id)}

    results = Repo.all(query, prefix: Triplex.to_prefix(tenant))

    Enum.map(results, fn {workflow_type, count} ->
      %{workflow_type: workflow_type, count: count}
    end)
  end

  defp get_team_key_metrics(_tenant, _department) do
    # Asset utilization: assigned / (assigned + in_stock)
    # These are simplified - in production you'd want more sophisticated calculations
    %{
      team_utilization: 85.0,
      onboarding_completion_rate: 92.0,
      avg_time_to_equipment: 2.3,
      assets_per_employee: 2.4
    }
  end

  # ============================================================================
  # Admin Dashboard
  # ============================================================================

  @doc """
  Gets dashboard data for an admin.

  Returns:
  - Asset inventory overview
  - Workflow metrics
  - Integration health
  - Employee status
  - Recent activity
  - Alerts

  Results are cached for 5 minutes.
  """
  def get_admin_dashboard(tenant, user_id) do
    Cache.get_or_compute("#{tenant}:admin:#{user_id}", fn ->
      fetch_admin_dashboard(tenant, user_id)
    end)
  end

  defp fetch_admin_dashboard(tenant, _user_id) do
    Logger.info("[Dashboard] Fetching admin dashboard for tenant #{tenant}")

    Logger.debug("[Dashboard] Fetching asset inventory...")
    asset_inventory = get_asset_inventory(tenant)
    Logger.debug("[Dashboard] Asset inventory loaded")

    Logger.debug("[Dashboard] Fetching workflow metrics...")
    workflow_metrics = get_workflow_metrics(tenant)
    Logger.debug("[Dashboard] Workflow metrics loaded")

    Logger.debug("[Dashboard] Fetching integration health...")
    integration_health = get_integration_health(tenant)
    Logger.debug("[Dashboard] Integration health loaded")

    Logger.debug("[Dashboard] Fetching employee status...")
    employee_status = get_employee_status(tenant)
    Logger.debug("[Dashboard] Employee status loaded")

    Logger.debug("[Dashboard] Fetching recent activity...")
    recent_activity = get_recent_activity(tenant)
    Logger.debug("[Dashboard] Recent activity loaded")

    Logger.debug("[Dashboard] Fetching alerts...")
    alerts = get_alerts(tenant)
    Logger.debug("[Dashboard] Alerts loaded")

    %{
      asset_inventory: asset_inventory,
      workflow_metrics: workflow_metrics,
      integration_health: integration_health,
      employee_status: employee_status,
      recent_activity: recent_activity,
      alerts: alerts
    }
  end

  defp get_asset_inventory(tenant) do
    status_query =
      from a in Asset,
        group_by: a.status,
        select: {a.status, count(a.id)}

    status_counts = Repo.all(status_query, prefix: Triplex.to_prefix(tenant))
    |> Enum.into(%{})

    total_query = from a in Asset, select: count(a.id)
    total = Repo.one(total_query, prefix: Triplex.to_prefix(tenant)) || 0

    # Calculate utilization rate
    assigned = Map.get(status_counts, "assigned", 0)
    in_stock = Map.get(status_counts, "in_stock", 0)
    utilization_rate =
      if (assigned + in_stock) > 0 do
        Float.round(assigned / (assigned + in_stock) * 100, 1)
      else
        0.0
      end

    # Warranty expiring soon
    warranty_expiring_query =
      from a in Asset,
        where: not is_nil(a.warranty_end_date),
        where: a.warranty_end_date >= ^Date.utc_today(),
        where: a.warranty_end_date <= ^Date.add(Date.utc_today(), 90),
        select: count(a.id)

    warranty_expiring = Repo.one(warranty_expiring_query, prefix: Triplex.to_prefix(tenant)) || 0

    %{
      total: total,
      by_status: %{
        in_stock: Map.get(status_counts, "in_stock", 0),
        assigned: Map.get(status_counts, "assigned", 0),
        in_repair: Map.get(status_counts, "in_repair", 0),
        retired: Map.get(status_counts, "retired", 0),
        on_order: Map.get(status_counts, "on_order", 0),
        in_transit: Map.get(status_counts, "in_transit", 0),
        lost: Map.get(status_counts, "lost", 0),
        stolen: Map.get(status_counts, "stolen", 0)
      },
      utilization_rate: utilization_rate,
      warranty_expiring_soon: warranty_expiring
    }
  end

  defp get_workflow_metrics(tenant) do
    active_by_type_query =
      from w in Workflow,
        where: w.status in ["pending", "in_progress"],
        group_by: w.workflow_type,
        select: {w.workflow_type, count(w.id)}

    active_by_type = Repo.all(active_by_type_query, prefix: Triplex.to_prefix(tenant))
    |> Enum.into(%{})

    overdue_query =
      from w in Workflow,
        where: w.status in ["pending", "in_progress"],
        where: not is_nil(w.due_date),
        where: w.due_date < ^Date.utc_today(),
        select: count(w.id)

    overdue = Repo.one(overdue_query, prefix: Triplex.to_prefix(tenant)) || 0

    # Average completion time by type (last 30 days)
    avg_completion_query =
      from w in Workflow,
        where: w.status == "completed",
        where: not is_nil(w.completed_at),
        where: not is_nil(w.started_at),
        where: w.completed_at >= ^DateTime.add(DateTime.utc_now(), -30, :day),
        group_by: w.workflow_type,
        select: {
          w.workflow_type,
          fragment("AVG(EXTRACT(EPOCH FROM (? - ?)))/3600", w.completed_at, w.started_at)
        }

    avg_completion_times = Repo.all(avg_completion_query, prefix: Triplex.to_prefix(tenant))
    |> Enum.map(fn {type, avg_hours} ->
      hours = case avg_hours do
        nil -> 0.0
        %Decimal{} = d -> d |> Decimal.to_float() |> Float.round(1)
        h when is_float(h) -> Float.round(h, 1)
        h when is_integer(h) -> h * 1.0
      end
      {type, hours}
    end)
    |> Enum.into(%{})

    %{
      active_by_type: %{
        onboarding: Map.get(active_by_type, "onboarding", 0),
        offboarding: Map.get(active_by_type, "offboarding", 0),
        repair: Map.get(active_by_type, "repair", 0),
        maintenance: Map.get(active_by_type, "maintenance", 0),
        procurement: Map.get(active_by_type, "procurement", 0)
      },
      overdue: overdue,
      avg_completion_time: avg_completion_times
    }
  end

  defp get_integration_health(tenant) do
    query =
      from i in Integrations.Integration,
        where: i.status == "active" and i.sync_enabled == true,
        select: %{
          id: i.id,
          provider: i.provider,
          name: i.name,
          last_sync_at: i.last_sync_at,
          last_sync_status: i.last_sync_status,
          last_sync_error: i.last_sync_error
        },
        order_by: [desc: i.last_sync_at]

    integrations = Repo.all(query, prefix: Triplex.to_prefix(tenant))

    # Calculate success rate (last 24 hours) - only for connected integrations
    twenty_four_hours_ago = DateTime.add(DateTime.utc_now(), -24, :hour)

    total_syncs_query =
      from i in Integrations.Integration,
        where: i.status == "active" and i.sync_enabled == true,
        where: not is_nil(i.last_sync_at),
        where: i.last_sync_at >= ^twenty_four_hours_ago,
        select: count(i.id)

    successful_syncs_query =
      from i in Integrations.Integration,
        where: i.status == "active" and i.sync_enabled == true,
        where: not is_nil(i.last_sync_at),
        where: i.last_sync_at >= ^twenty_four_hours_ago,
        where: i.last_sync_status == "success",
        select: count(i.id)

    total_syncs = Repo.one(total_syncs_query, prefix: Triplex.to_prefix(tenant)) || 0
    successful_syncs = Repo.one(successful_syncs_query, prefix: Triplex.to_prefix(tenant)) || 0

    success_rate =
      if total_syncs > 0 do
        Float.round(successful_syncs / total_syncs * 100, 1)
      else
        0.0
      end

    failed_count = Enum.count(integrations, fn i -> i.last_sync_status == "failed" end)

    %{
      integrations: integrations,
      success_rate_24h: success_rate,
      failed_syncs: failed_count
    }
  end

  defp get_employee_status(tenant) do
    thirty_days_ago = Date.add(Date.utc_today(), -30)

    query =
      from e in Employee,
        select: %{
          total: count(e.id),
          active: fragment("COUNT(CASE WHEN ? = 'active' THEN 1 END)", e.employment_status),
          new_hires: fragment("COUNT(CASE WHEN ? >= ? THEN 1 END)", e.hire_date, ^thirty_days_ago),
          terminations: fragment("COUNT(CASE WHEN ? >= ? AND ? IS NOT NULL THEN 1 END)", e.termination_date, ^thirty_days_ago, e.termination_date)
        }

    Repo.one(query, prefix: Triplex.to_prefix(tenant)) || %{
      total: 0,
      active: 0,
      new_hires: 0,
      terminations: 0
    }
  end

  defp get_recent_activity(tenant) do
    query =
      from t in Transaction,
        left_join: a in assoc(t, :asset),
        left_join: e in assoc(t, :employee),
        order_by: [desc: t.performed_at],
        limit: 20,
        select: %{
          id: t.id,
          type: t.transaction_type,
          description: t.description,
          performed_at: t.performed_at,
          asset_name: a.name,
          employee_name: fragment("CONCAT(?, ' ', ?)", e.first_name, e.last_name)
        }

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  defp get_alerts(tenant) do
    alerts = []
    failed_integrations_query =  from i in Integrations.Integration, where: i.last_sync_status == "failed", select: count(i.id)
    failed_integrations = Repo.one(failed_integrations_query, prefix: Triplex.to_prefix(tenant)) || 0
    alerts = if failed_integrations > 0 do
        [%{
          severity: "error", type: "integration_failure",  message: "#{failed_integrations} integration(s) failing", count: failed_integrations
        } | alerts]
      else
        alerts
      end

    overdue_workflows_query = from w in Workflow, where: w.status in ["pending", "in_progress"], where: not is_nil(w.due_date),
        where: w.due_date < ^Date.utc_today(), select: count(w.id)

    overdue_workflows = Repo.one(overdue_workflows_query, prefix: Triplex.to_prefix(tenant)) || 0
    alerts = if overdue_workflows > 0 do
        [%{
          severity: "warning",
          type: "overdue_workflows",
          message: "#{overdue_workflows} workflow(s) overdue",
          count: overdue_workflows
        } | alerts]
      else
        alerts
      end

    # Check for assets past expected return date
    past_return_query =
      from a in Asset,
        where: not is_nil(a.expected_return_date),
        where: a.expected_return_date < ^Date.utc_today(),
        where: a.status == "assigned",
        select: count(a.id)

    past_return = Repo.one(past_return_query, prefix: Triplex.to_prefix(tenant)) || 0

    alerts =
      if past_return > 0 do
        [%{
          severity: "warning",
          type: "past_return_date",
          message: "#{past_return} asset(s) past expected return date",
          count: past_return
        } | alerts]
      else
        alerts
      end

    alerts
  end
end
