defmodule Assetronics.Policies.WorkflowPolicy do
  @moduledoc """
  Authorization policy for Workflow resources.

  Defines permissions for workflow management and execution.
  """

  @behaviour Bodyguard.Policy

  alias Assetronics.Accounts.User
  alias Assetronics.Workflows.Workflow
  alias Assetronics.Policy

  @doc """
  Authorizes workflow actions based on role and assignment.

  ## Actions
  - :list_workflows - List all workflows (all authenticated users)
  - :show_workflow - View workflow details (all authenticated users)
  - :create_workflow - Create workflow template (admin, manager)
  - :update_workflow - Update workflow template (admin, manager)
  - :delete_workflow - Delete workflow template (admin only)
  - :execute_workflow - Start workflow execution (admin, manager)
  - :complete_task - Complete assigned task (task assignee or admin/manager)
  - :cancel_execution - Cancel workflow execution (admin, manager)
  """

  # List workflows - all authenticated users
  def authorize(:list_workflows, %User{} = user, _params) do
    Policy.active?(user)
  end

  # Show workflow - all authenticated users
  def authorize(:show_workflow, %User{} = user, %Workflow{}) do
    Policy.active?(user)
  end

  # Create workflow - managers and admins
  def authorize(:create_workflow, %User{} = user, _params) do
    Policy.manager_or_higher?(user) && Policy.active?(user)
  end

  # Update workflow - managers and admins
  def authorize(:update_workflow, %User{} = user, %Workflow{}) do
    Policy.manager_or_higher?(user) && Policy.active?(user)
  end

  # Delete workflow - admins only
  def authorize(:delete_workflow, %User{} = user, %Workflow{}) do
    Policy.admin?(user) && Policy.active?(user)
  end

  # Execute workflow - managers and admins
  def authorize(:execute_workflow, %User{} = user, %Workflow{}) do
    Policy.manager_or_higher?(user) && Policy.active?(user)
  end

  # Complete task - task assignee or managers/admins
  def authorize(:complete_task, %User{} = user, %{assigned_to_id: assignee_id}) do
    Policy.active?(user) &&
      (user.id == assignee_id || Policy.manager_or_higher?(user))
  end

  # Cancel execution - managers and admins
  def authorize(:cancel_execution, %User{} = user, _workflow_execution) do
    Policy.manager_or_higher?(user) && Policy.active?(user)
  end

  # Default deny
  def authorize(_action, _user, _params), do: false
end
