defmodule AssetronicsWeb.WorkflowController do
  use AssetronicsWeb, :controller

  alias Assetronics.Workflows
  alias Assetronics.Workflows.Workflow

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  List all workflows for the tenant.

  Query parameters:
  - workflow_type: Filter by type (onboarding, offboarding, maintenance, audit, asset_refresh, custom)
  - status: Filter by status (pending, in_progress, completed, cancelled)
  - employee_id: Filter by employee
  - priority: Filter by priority (low, medium, high, urgent)
  """
  def index(conn, params) do
    tenant = conn.assigns[:tenant]
    opts = build_filters(params)
    workflows = Workflows.list_workflows(tenant, opts)
    render(conn, :index, workflows: workflows)
  end

  @doc """
  Create a new workflow.
  """
  def create(conn, %{"workflow" => workflow_params}) do
    tenant = conn.assigns[:tenant]

    with {:ok, %Workflow{} = workflow} <- Workflows.create_workflow(tenant, workflow_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/v1/workflows/#{workflow.id}")
      |> render(:show, workflow: workflow)
    end
  end

  @doc """
  Get a single workflow by ID.
  """
  def show(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    workflow = Workflows.get_workflow!(tenant, id)
    render(conn, :show, workflow: workflow)
  end

  @doc """
  Update a workflow.
  """
  def update(conn, %{"id" => id, "workflow" => workflow_params}) do
    tenant = conn.assigns[:tenant]
    workflow = Workflows.get_workflow!(tenant, id)

    with {:ok, %Workflow{} = workflow} <- Workflows.update_workflow(tenant, workflow, workflow_params) do
      render(conn, :show, workflow: workflow)
    end
  end

  @doc """
  Delete a workflow.
  """
  def delete(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    workflow = Workflows.get_workflow!(tenant, id)

    with {:ok, %Workflow{}} <- Workflows.delete_workflow(tenant, workflow) do
      send_resp(conn, :no_content, "")
    end
  end

  @doc """
  Start a workflow.

  Changes status from pending to in_progress and sets started_at timestamp.
  """
  def start(conn, %{"workflow_id" => id}) do
    tenant = conn.assigns[:tenant]
    workflow = Workflows.get_workflow!(tenant, id)

    with {:ok, %Workflow{} = workflow} <- Workflows.start_workflow(tenant, workflow) do
      render(conn, :show, workflow: workflow)
    end
  end

  @doc """
  Complete a workflow.

  Changes status to completed and sets completed_at timestamp.
  """
  def complete(conn, %{"workflow_id" => id}) do
    tenant = conn.assigns[:tenant]
    workflow = Workflows.get_workflow!(tenant, id)

    with {:ok, %Workflow{} = workflow} <- Workflows.complete_workflow(tenant, workflow) do
      render(conn, :show, workflow: workflow)
    end
  end

  @doc """
  Cancel a workflow.

  Request body:
  {
    "reason": "Employee left before onboarding completed"
  }
  """
  def cancel(conn, %{"workflow_id" => id} = params) do
    tenant = conn.assigns[:tenant]
    workflow = Workflows.get_workflow!(tenant, id)
    reason = params["reason"] || "Cancelled"

    with {:ok, %Workflow{} = workflow} <- Workflows.cancel_workflow(tenant, workflow, reason) do
      render(conn, :show, workflow: workflow)
    end
  end

  @doc """
  Advance to next workflow step.

  Increments current_step and updates the steps array to mark current step as completed.
  """
  def advance_step(conn, %{"workflow_id" => id}) do
    tenant = conn.assigns[:tenant]
    workflow = Workflows.get_workflow!(tenant, id)

    with {:ok, %Workflow{} = workflow} <- Workflows.advance_workflow_step(tenant, workflow) do
      render(conn, :show, workflow: workflow)
    end
  end

  @doc """
  Get overdue workflows.
  """
  def overdue(conn, _params) do
    tenant = conn.assigns[:tenant]
    workflows = Workflows.list_overdue_workflows(tenant)
    render(conn, :index, workflows: workflows)
  end

  @doc """
  List all available workflow templates.

  Returns:
  [
    {
      "key": "incoming_hardware",
      "name": "Incoming Hardware Setup",
      "type": "procurement",
      "description": "Complete process for receiving, configuring, and deploying new hardware",
      "estimated_duration_days": 3,
      "step_count": 8
    },
    ...
  ]
  """
  def templates(conn, _params) do
    templates = Workflows.list_available_templates()
    render(conn, :templates, templates: templates)
  end

  @doc """
  Create a workflow from a template.

  Request body:
  {
    "template_key": "incoming_hardware",
    "asset_id": "uuid",
    "employee_id": "uuid",  // optional
    "assigned_to": "it@company.com",  // optional
    "due_date": "2025-12-15",  // optional
    "priority": "high"  // optional
  }
  """
  def create_from_template(conn, %{"template_key" => template_key} = params) do
    tenant = conn.assigns[:tenant]
    template_atom = String.to_existing_atom(template_key)

    attrs = %{
      asset_id: params["asset_id"],
      employee_id: params["employee_id"],
      assigned_to: params["assigned_to"],
      due_date: parse_date(params["due_date"]),
      priority: params["priority"] || "normal"
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()

    with {:ok, %Workflow{} = workflow} <- Workflows.create_from_template(tenant, template_atom, attrs) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/v1/workflows/#{workflow.id}")
      |> render(:show, workflow: workflow)
    end
  rescue
    ArgumentError ->
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Invalid template_key. Use one of: incoming_hardware, new_employee, equipment_return, emergency_replacement"})
  end

  # Private helpers

  defp parse_date(nil), do: nil
  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end
  defp parse_date(_), do: nil

  defp build_filters(params) do
    []
    |> add_filter(:workflow_type, params["workflow_type"])
    |> add_filter(:status, params["status"])
    |> add_filter(:employee_id, params["employee_id"])
    |> add_filter(:priority, params["priority"])
  end

  defp add_filter(filters, _key, nil), do: filters
  defp add_filter(filters, _key, ""), do: filters
  defp add_filter(filters, key, value), do: [{key, value} | filters]
end
