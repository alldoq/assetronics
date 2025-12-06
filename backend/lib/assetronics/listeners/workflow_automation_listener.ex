defmodule Assetronics.Listeners.WorkflowAutomationListener do
  @moduledoc """
  Subscribes to PubSub events and automatically creates workflows based on system events.

  This listener enables event-driven workflow automation:
  - Employee termination → offboarding workflow
  - Asset damage/repair → repair workflow
  - Integration sync completion → follow-up workflows

  Each tenant has its own listener process.
  """

  use GenServer
  require Logger

  alias Assetronics.Workflows
  alias Assetronics.Repo

  @doc """
  Starts the workflow automation listener for a specific tenant.
  """
  def start_link(tenant) do
    GenServer.start_link(__MODULE__, tenant, name: via_tuple(tenant))
  end

  @doc """
  Returns the child spec for the dynamic supervisor.
  """
  def child_spec(tenant) do
    %{
      id: {__MODULE__, tenant},
      start: {__MODULE__, :start_link, [tenant]},
      restart: :permanent,
      type: :worker
    }
  end

  ## Callbacks

  @impl true
  def init(tenant) do
    # Subscribe to all relevant event topics
    Phoenix.PubSub.subscribe(Assetronics.PubSub, "employees:#{tenant}")
    Phoenix.PubSub.subscribe(Assetronics.PubSub, "assets:#{tenant}")
    Phoenix.PubSub.subscribe(Assetronics.PubSub, "integrations:#{tenant}")

    Logger.info("[WorkflowAutomationListener] Started for tenant: #{tenant}")

    {:ok, %{tenant: tenant}}
  end

  @impl true
  def handle_info({"employee_terminated", employee}, state) do
    Logger.info("[WorkflowAutomationListener] Employee terminated: #{employee.id}, creating offboarding workflow")

    # Create offboarding workflow for terminated employee
    case Workflows.create_offboarding_workflow(state.tenant, employee) do
      {:ok, workflow} ->
        Logger.info("[WorkflowAutomationListener] Created offboarding workflow #{workflow.id} for employee #{employee.id}")

      {:error, reason} ->
        Logger.error("[WorkflowAutomationListener] Failed to create offboarding workflow: #{inspect(reason)}")
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({"asset_status_changed", asset}, state) do
    # Create repair workflow if asset status changed to "in_repair"
    if asset.status == "in_repair" do
      Logger.info("[WorkflowAutomationListener] Asset #{asset.id} marked for repair, checking for workflow")

      # Check if repair workflow already exists for this asset
      existing_workflows = Workflows.list_workflows_for_asset(state.tenant, asset.id)
      has_repair_workflow = Enum.any?(existing_workflows, fn w ->
        w.workflow_type == "repair" && w.status in ["pending", "in_progress"]
      end)

      if !has_repair_workflow do
        # Get employee if asset is assigned
        employee = if asset.employee_id do
          Repo.get(Assetronics.Employees.Employee, asset.employee_id, prefix: Triplex.to_prefix(state.tenant))
        else
          nil
        end

        attrs = %{
          workflow_type: "repair",
          title: "Repair: #{asset.name || asset.asset_tag}",
          asset_id: asset.id,
          employee_id: if(employee, do: employee.id, else: nil),
          status: "pending",
          priority: "normal",
          due_date: Date.add(Date.utc_today(), 5),
          steps: [
            %{name: "Diagnose issue", status: "pending", completed_at: nil},
            %{name: "Order parts if needed", status: "pending", completed_at: nil},
            %{name: "Perform repair", status: "pending", completed_at: nil},
            %{name: "Test and verify", status: "pending", completed_at: nil}
          ],
          triggered_by: "asset_status_change"
        }

        case Workflows.create_workflow(state.tenant, attrs) do
          {:ok, workflow} ->
            Logger.info("[WorkflowAutomationListener] Created repair workflow #{workflow.id} for asset #{asset.id}")

          {:error, reason} ->
            Logger.error("[WorkflowAutomationListener] Failed to create repair workflow: #{inspect(reason)}")
        end
      end
    end

    # Create lost/stolen workflow if asset status changed to "lost" or "stolen"
    if asset.status in ["lost", "stolen"] do
      Logger.info("[WorkflowAutomationListener] Asset #{asset.id} marked as #{asset.status}, creating incident workflow")

      attrs = %{
        workflow_type: "incident",
        title: "#{String.capitalize(asset.status)}: #{asset.name || asset.asset_tag}",
        asset_id: asset.id,
        status: "pending",
        priority: "urgent",
        due_date: Date.add(Date.utc_today(), 1),
        steps: [
          %{name: "File incident report", status: "pending", completed_at: nil},
          %{name: "Notify insurance", status: "pending", completed_at: nil},
          %{name: "Update inventory", status: "pending", completed_at: nil},
          %{name: "Security review", status: "pending", completed_at: nil}
        ],
        triggered_by: "asset_status_change"
      }

      case Workflows.create_workflow(state.tenant, attrs) do
        {:ok, workflow} ->
          Logger.info("[WorkflowAutomationListener] Created incident workflow #{workflow.id} for asset #{asset.id}")

        {:error, reason} ->
          Logger.error("[WorkflowAutomationListener] Failed to create incident workflow: #{inspect(reason)}")
      end
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({"integration_sync_completed", integration}, state) do
    Logger.debug("[WorkflowAutomationListener] Integration sync completed: #{integration.provider}")
    {:noreply, state}
  end

  @impl true
  def handle_info({"employee_synced", employee}, state) do
    Logger.debug("[WorkflowAutomationListener] Employee synced: #{employee.id}")
    # Workflow creation for new employees is already handled in assign_asset
    # This is just for logging/monitoring
    {:noreply, state}
  end

  # Catch-all for events we don't handle yet
  @impl true
  def handle_info(event, state) do
    Logger.debug("[WorkflowAutomationListener] Received unhandled event: #{inspect(elem(event, 0))}")
    {:noreply, state}
  end

  ## Private Functions

  defp via_tuple(tenant) do
    {:via, Registry, {Assetronics.ListenerRegistry, {__MODULE__, tenant}}}
  end
end
