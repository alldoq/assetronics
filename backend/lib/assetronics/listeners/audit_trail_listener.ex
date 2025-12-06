defmodule Assetronics.Listeners.AuditTrailListener do
  @moduledoc """
  Subscribes to PubSub events and creates audit trail records for non-asset changes.

  This listener expands the audit trail beyond assets to include:
  - Employee lifecycle events (hire, termination, updates)
  - Workflow state changes
  - Integration sync events
  - Settings changes

  Each tenant has its own listener process.
  """

  use GenServer
  require Logger

  alias Assetronics.Repo
  alias Assetronics.Transactions.Transaction

  @doc """
  Starts the audit trail listener for a specific tenant.
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
    Phoenix.PubSub.subscribe(Assetronics.PubSub, "workflows:#{tenant}")
    Phoenix.PubSub.subscribe(Assetronics.PubSub, "integrations:#{tenant}")

    Logger.info("[AuditTrailListener] Started for tenant: #{tenant}")

    {:ok, %{tenant: tenant}}
  end

  @impl true
  def handle_info({"employee_created", employee}, state) do
    create_audit_record(state.tenant, %{
      transaction_type: "employee_created",
      description: "Employee created: #{employee.first_name} #{employee.last_name}",
      employee_id: employee.id,
      performed_by: employee.email,
      metadata: %{
        employee_id: employee.employee_id,
        hris_id: employee.hris_id,
        email: employee.email,
        job_title: employee.job_title,
        hire_date: employee.hire_date
      }
    })

    {:noreply, state}
  end

  @impl true
  def handle_info({"employee_updated", employee}, state) do
    create_audit_record(state.tenant, %{
      transaction_type: "employee_updated",
      description: "Employee updated: #{employee.first_name} #{employee.last_name}",
      employee_id: employee.id,
      performed_by: "system",
      metadata: %{
        email: employee.email,
        job_title: employee.job_title,
        employment_status: employee.employment_status
      }
    })

    {:noreply, state}
  end

  @impl true
  def handle_info({"employee_terminated", employee}, state) do
    create_audit_record(state.tenant, %{
      transaction_type: "employee_terminated",
      description: "Employee terminated: #{employee.first_name} #{employee.last_name}",
      employee_id: employee.id,
      performed_by: "system",
      metadata: %{
        email: employee.email,
        termination_date: employee.termination_date,
        employment_status: employee.employment_status
      }
    })

    {:noreply, state}
  end

  @impl true
  def handle_info({"employee_synced", employee}, state) do
    create_audit_record(state.tenant, %{
      transaction_type: "employee_synced",
      description: "Employee synced from HRIS: #{employee.first_name} #{employee.last_name}",
      employee_id: employee.id,
      performed_by: "hris_integration",
      metadata: %{
        sync_source: employee.sync_source,
        hris_id: employee.hris_id,
        last_synced_at: employee.last_synced_at
      }
    })

    {:noreply, state}
  end

  @impl true
  def handle_info({"workflow_created", workflow}, state) do
    create_audit_record(state.tenant, %{
      transaction_type: "workflow_created",
      description: "Workflow created: #{workflow.title}",
      workflow_id: workflow.id,
      employee_id: workflow.employee_id,
      asset_id: workflow.asset_id,
      performed_by: workflow.triggered_by || "system",
      metadata: %{
        workflow_type: workflow.workflow_type,
        status: workflow.status,
        priority: workflow.priority,
        due_date: workflow.due_date,
        assigned_to: workflow.assigned_to
      }
    })

    {:noreply, state}
  end

  @impl true
  def handle_info({"workflow_started", workflow}, state) do
    create_audit_record(state.tenant, %{
      transaction_type: "workflow_started",
      description: "Workflow started: #{workflow.title}",
      workflow_id: workflow.id,
      employee_id: workflow.employee_id,
      asset_id: workflow.asset_id,
      performed_by: workflow.assigned_to || "system",
      metadata: %{
        workflow_type: workflow.workflow_type,
        started_at: workflow.started_at
      }
    })

    {:noreply, state}
  end

  @impl true
  def handle_info({"workflow_completed", workflow}, state) do
    create_audit_record(state.tenant, %{
      transaction_type: "workflow_completed",
      description: "Workflow completed: #{workflow.title}",
      workflow_id: workflow.id,
      employee_id: workflow.employee_id,
      asset_id: workflow.asset_id,
      performed_by: workflow.assigned_to || "system",
      metadata: %{
        workflow_type: workflow.workflow_type,
        completed_at: workflow.completed_at,
        duration_days: calculate_duration(workflow.started_at, workflow.completed_at)
      }
    })

    {:noreply, state}
  end

  @impl true
  def handle_info({"workflow_step_advanced", workflow}, state) do
    current_step_name = get_current_step_name(workflow)

    create_audit_record(state.tenant, %{
      transaction_type: "workflow_step_advanced",
      description: "Workflow step advanced: #{workflow.title} -> #{current_step_name}",
      workflow_id: workflow.id,
      employee_id: workflow.employee_id,
      asset_id: workflow.asset_id,
      performed_by: workflow.assigned_to || "system",
      metadata: %{
        current_step: workflow.current_step,
        step_name: current_step_name
      }
    })

    {:noreply, state}
  end

  @impl true
  def handle_info({"integration_sync_completed", integration}, state) do
    create_audit_record(state.tenant, %{
      transaction_type: "integration_sync_completed",
      description: "Integration sync completed: #{integration.provider}",
      integration_id: integration.id,
      performed_by: "integration_worker",
      metadata: %{
        provider: integration.provider,
        sync_type: integration.integration_type,
        last_sync_at: integration.last_sync_at,
        last_sync_status: integration.last_sync_status
      }
    })

    {:noreply, state}
  end

  @impl true
  def handle_info({"integration_sync_failed", integration}, state) do
    create_audit_record(state.tenant, %{
      transaction_type: "integration_sync_failed",
      description: "Integration sync failed: #{integration.provider}",
      integration_id: integration.id,
      performed_by: "integration_worker",
      metadata: %{
        provider: integration.provider,
        sync_type: integration.integration_type,
        last_sync_at: integration.last_sync_at,
        error: integration.last_sync_error
      }
    })

    {:noreply, state}
  end

  # Catch-all for events we don't handle yet
  @impl true
  def handle_info(event, state) do
    Logger.debug("[AuditTrailListener] Received unhandled event: #{inspect(elem(event, 0))}")
    {:noreply, state}
  end

  ## Private Functions

  defp create_audit_record(tenant, attrs) do
    attrs_with_timestamp = Map.put(attrs, :performed_at, DateTime.utc_now())

    case Transaction.audit_changeset(attrs_with_timestamp)
         |> Repo.insert(prefix: Triplex.to_prefix(tenant)) do
      {:ok, transaction} ->
        Logger.debug("[AuditTrailListener] Created audit record: #{transaction.transaction_type}")
        :ok

      {:error, changeset} ->
        Logger.error("[AuditTrailListener] Failed to create audit record: #{inspect(changeset.errors)}")
        :error
    end
  end

  defp get_current_step_name(workflow) do
    if workflow.steps && workflow.current_step < length(workflow.steps) do
      step = Enum.at(workflow.steps, workflow.current_step)
      step["name"] || "Step #{workflow.current_step + 1}"
    else
      "Final step"
    end
  end

  defp calculate_duration(nil, _), do: nil
  defp calculate_duration(_, nil), do: nil
  defp calculate_duration(started_at, completed_at) do
    NaiveDateTime.diff(completed_at, started_at, :day)
  end

  defp via_tuple(tenant) do
    {:via, Registry, {Assetronics.ListenerRegistry, {__MODULE__, tenant}}}
  end
end
