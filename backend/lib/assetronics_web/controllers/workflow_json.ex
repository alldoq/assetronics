defmodule AssetronicsWeb.WorkflowJSON do
  alias Assetronics.Workflows.Workflow

  @doc """
  Renders a list of workflows.
  """
  def index(%{workflows: workflows}) do
    %{data: for(workflow <- workflows, do: data(workflow))}
  end

  @doc """
  Renders a single workflow.
  """
  def show(%{workflow: workflow}) do
    %{data: data(workflow)}
  end

  @doc """
  Renders a list of workflow templates.
  """
  def templates(%{templates: templates}) do
    %{data: templates}
  end

  defp data(%Workflow{} = workflow) do
    %{
      id: workflow.id,
      workflow_type: workflow.workflow_type,
      title: workflow.title,
      description: workflow.description,
      status: workflow.status,
      priority: workflow.priority,
      current_step: workflow.current_step,
      total_steps: length(workflow.steps || []),
      steps: workflow.steps,
      due_date: workflow.due_date,
      started_at: workflow.started_at,
      completed_at: workflow.completed_at,
      cancelled_at: workflow.cancelled_at,
      cancellation_reason: get_in(workflow.metadata, ["cancellation_reason"]),
      triggered_by: workflow.triggered_by,
      assigned_to: workflow.assigned_to,
      metadata: workflow.metadata,
      inserted_at: workflow.inserted_at,
      updated_at: workflow.updated_at
    }
    |> maybe_add_employee(workflow)
    |> maybe_add_asset(workflow)
  end

  defp maybe_add_employee(data, %Workflow{employee: %Ecto.Association.NotLoaded{}}), do: data
  defp maybe_add_employee(data, %Workflow{employee: nil}), do: data
  defp maybe_add_employee(data, %Workflow{employee: employee}) do
    Map.put(data, :employee, %{
      id: employee.id,
      email: employee.email,
      first_name: employee.first_name,
      last_name: employee.last_name,
      job_title: employee.job_title,
      department: employee.department
    })
  end
  defp maybe_add_employee(data, _), do: data

  defp maybe_add_asset(data, %Workflow{asset: %Ecto.Association.NotLoaded{}}), do: data
  defp maybe_add_asset(data, %Workflow{asset: nil}), do: data
  defp maybe_add_asset(data, %Workflow{asset: asset}) do
    Map.put(data, :asset, %{
      id: asset.id,
      asset_tag: asset.asset_tag,
      name: asset.name,
      category: asset.category,
      status: asset.status
    })
  end
  defp maybe_add_asset(data, _), do: data
end
