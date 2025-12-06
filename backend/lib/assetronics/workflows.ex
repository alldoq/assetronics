defmodule Assetronics.Workflows do
  @moduledoc """
  The Workflows context.

  Handles workflow automation:
  - Onboarding and offboarding workflows
  - Repair and maintenance workflows
  - Procurement workflows
  - Status tracking and approvals
  """

  import Ecto.Query, warn: false
  alias Assetronics.Repo
  alias Assetronics.Workflows.Workflow
  alias Assetronics.Workflows.Templates
  alias Assetronics.Accounts
  alias Assetronics.Notifications

  require Logger

  @doc """
  Returns the list of workflows for a tenant.

  ## Examples

      iex> list_workflows("acme")
      [%Workflow{}, ...]

  """
  def list_workflows(tenant, opts \\ []) do
    query = from(w in Workflow,
      order_by: [desc: w.inserted_at],
      preload: [:employee, :asset]
    )

    query
    |> apply_filters(opts)
    |> then(&Repo.all(&1, prefix: Triplex.to_prefix(tenant)))
  end

  @doc """
  Gets a single workflow.

  Raises `Ecto.NoResultsError` if the Workflow does not exist.

  ## Examples

      iex> get_workflow!("acme", "123")
      %Workflow{}

  """
  def get_workflow!(tenant, id) do
    Repo.get!(Workflow, id, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Creates a workflow.

  ## Examples

      iex> create_workflow("acme", %{workflow_type: "onboarding", title: "New hire setup"})
      {:ok, %Workflow{}}

  """
  def create_workflow(tenant, attrs \\ %{}) do
    start_time = System.monotonic_time()
    workflow_type = Map.get(attrs, :workflow_type, "unknown")

    result =
      %Workflow{}
      |> Workflow.changeset(attrs)
      |> Repo.insert(prefix: Triplex.to_prefix(tenant))
      |> broadcast_result(tenant, "workflow_created")

    # Emit telemetry
    duration = System.monotonic_time() - start_time
    case result do
      {:ok, _workflow} ->
        :telemetry.execute(
          [:assetronics, :workflows, :create, :stop],
          %{duration: duration},
          %{tenant: tenant, workflow_type: workflow_type, status: :success}
        )
        :telemetry.execute(
          [:assetronics, :workflows, :create, :success],
          %{count: 1},
          %{tenant: tenant, workflow_type: workflow_type}
        )

      {:error, _changeset} ->
        :telemetry.execute(
          [:assetronics, :workflows, :create, :stop],
          %{duration: duration},
          %{tenant: tenant, workflow_type: workflow_type, status: :failure}
        )
        :telemetry.execute(
          [:assetronics, :workflows, :create, :failure],
          %{count: 1},
          %{tenant: tenant, workflow_type: workflow_type}
        )
    end

    result
  end

  @doc """
  Updates a workflow.

  ## Examples

      iex> update_workflow("acme", workflow, %{status: "in_progress"})
      {:ok, %Workflow{}}

  """
  def update_workflow(tenant, %Workflow{} = workflow, attrs) do
    workflow
    |> Workflow.changeset(attrs)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "workflow_updated")
  end

  @doc """
  Deletes a workflow.

  ## Examples

      iex> delete_workflow("acme", workflow)
      {:ok, %Workflow{}}

  """
  def delete_workflow(tenant, %Workflow{} = workflow) do
    Repo.delete(workflow, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking workflow changes.

  ## Examples

      iex> change_workflow(workflow)
      %Ecto.Changeset{data: %Workflow{}}

  """
  def change_workflow(%Workflow{} = workflow, attrs \\ %{}) do
    Workflow.changeset(workflow, attrs)
  end

  @doc """
  Starts a workflow.

  ## Examples

      iex> start_workflow("acme", workflow)
      {:ok, %Workflow{}}

  """
  def start_workflow(tenant, %Workflow{} = workflow, attrs \\ %{}) do
    workflow
    |> Workflow.start_changeset(attrs)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "workflow_started")
  end

  @doc """
  Completes a workflow.

  ## Examples

      iex> complete_workflow("acme", workflow)
      {:ok, %Workflow{}}

  """
  def complete_workflow(tenant, %Workflow{} = workflow, attrs \\ %{}) do
    start_time = System.monotonic_time()
    workflow_type = workflow.workflow_type

    result =
      workflow
      |> Workflow.complete_changeset(attrs)
      |> Repo.update(prefix: Triplex.to_prefix(tenant))
      |> broadcast_result(tenant, "workflow_completed")

    # Emit telemetry
    duration = System.monotonic_time() - start_time
    case result do
      {:ok, _workflow} ->
        :telemetry.execute(
          [:assetronics, :workflows, :complete, :stop],
          %{duration: duration},
          %{tenant: tenant, workflow_type: workflow_type, status: :success}
        )
        :telemetry.execute(
          [:assetronics, :workflows, :complete, :success],
          %{count: 1},
          %{tenant: tenant, workflow_type: workflow_type}
        )

      {:error, _changeset} ->
        :telemetry.execute(
          [:assetronics, :workflows, :complete, :stop],
          %{duration: duration},
          %{tenant: tenant, workflow_type: workflow_type, status: :failure}
        )
        :telemetry.execute(
          [:assetronics, :workflows, :complete, :failure],
          %{count: 1},
          %{tenant: tenant, workflow_type: workflow_type}
        )
    end

    result
  end

  @doc """
  Cancels a workflow.

  ## Examples

      iex> cancel_workflow("acme", workflow, "No longer needed")
      {:ok, %Workflow{}}

  """
  def cancel_workflow(tenant, %Workflow{} = workflow, reason) do
    workflow
    |> Workflow.cancel_changeset(reason)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "workflow_cancelled")
  end

  @doc """
  Advances workflow to next step.

  Marks the current step as completed and increments current_step.

  ## Examples

      iex> advance_workflow_step("acme", workflow)
      {:ok, %Workflow{}}

  """
  def advance_workflow_step(tenant, %Workflow{} = workflow) do
    current_step = workflow.current_step
    steps = workflow.steps || []

    if current_step < length(steps) do
      # Mark the current step as completed
      updated_steps =
        steps
        |> Enum.with_index()
        |> Enum.map(fn {step, index} ->
          if index == current_step do
            step
            |> Map.put("completed", true)
            |> Map.put("completed_at", DateTime.utc_now() |> DateTime.to_iso8601())
          else
            step
          end
        end)

      workflow
      |> Workflow.changeset(%{
        current_step: current_step + 1,
        steps: updated_steps
      })
      |> Repo.update(prefix: Triplex.to_prefix(tenant))
      |> broadcast_result(tenant, "workflow_step_advanced")
    else
      {:error, :last_step}
    end
  end

  @doc """
  Lists active workflows (pending or in_progress).

  ## Examples

      iex> list_active_workflows("acme")
      [%Workflow{}, ...]

  """
  def list_active_workflows(tenant) do
    query =
      from w in Workflow,
        where: w.status in ["pending", "in_progress"],
        order_by: [desc: w.priority, asc: w.due_date],
        preload: [:asset, :employee]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Lists workflows by type.

  ## Examples

      iex> list_workflows_by_type("acme", "onboarding")
      [%Workflow{}, ...]

  """
  def list_workflows_by_type(tenant, workflow_type) do
    query =
      from w in Workflow,
        where: w.workflow_type == ^workflow_type,
        order_by: [desc: w.inserted_at],
        preload: [:asset, :employee]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Lists workflows for an employee.

  ## Examples

      iex> list_workflows_for_employee("acme", employee_id)
      [%Workflow{}, ...]

  """
  def list_workflows_for_employee(tenant, employee_id) do
    query =
      from w in Workflow,
        where: w.employee_id == ^employee_id,
        order_by: [desc: w.inserted_at],
        preload: [:asset]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Lists workflows for an asset.

  ## Examples

      iex> list_workflows_for_asset("acme", asset_id)
      [%Workflow{}, ...]

  """
  def list_workflows_for_asset(tenant, asset_id) do
    query =
      from w in Workflow,
        where: w.asset_id == ^asset_id,
        order_by: [desc: w.inserted_at],
        preload: [:employee]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Lists overdue workflows.

  ## Examples

      iex> list_overdue_workflows("acme")
      [%Workflow{}, ...]

  """
  def list_overdue_workflows(tenant) do
    today = Date.utc_today()

    query =
      from w in Workflow,
        where: w.status in ["pending", "in_progress"],
        where: w.due_date < ^today,
        order_by: [asc: w.due_date],
        preload: [:asset, :employee]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Creates an onboarding workflow for a new employee.

  ## Examples

      iex> create_onboarding_workflow("acme", employee, asset)
      {:ok, %Workflow{}}

  """
  def create_onboarding_workflow(tenant, employee, asset \\ nil, opts \\ []) do
    due_date = Keyword.get(opts, :due_date, Date.add(Date.utc_today(), 7))

    steps = [
      %{name: "Create accounts", status: "pending", completed_at: nil},
      %{name: "Assign hardware", status: "pending", completed_at: nil},
      %{name: "Setup software", status: "pending", completed_at: nil},
      %{name: "Send welcome email", status: "pending", completed_at: nil}
    ]

    attrs = %{
      workflow_type: "onboarding",
      title: "Onboarding: #{employee.email}",
      employee_id: employee.id,
      asset_id: if(asset, do: asset.id, else: nil),
      status: "pending",
      priority: "high",
      due_date: due_date,
      steps: steps,
      triggered_by: "hris_sync"
    }

    create_workflow(tenant, attrs)
  end

  @doc """
  Creates an offboarding workflow for a departing employee.

  ## Examples

      iex> create_offboarding_workflow("acme", employee)
      {:ok, %Workflow{}}

  """
  def create_offboarding_workflow(tenant, employee, opts \\ []) do
    due_date = Keyword.get(opts, :due_date, Date.add(Date.utc_today(), 3))

    steps = [
      %{name: "Collect hardware", status: "pending", completed_at: nil},
      %{name: "Revoke access", status: "pending", completed_at: nil},
      %{name: "Export data", status: "pending", completed_at: nil},
      %{name: "Final checklist", status: "pending", completed_at: nil}
    ]

    attrs = %{
      workflow_type: "offboarding",
      title: "Offboarding: #{employee.email}",
      employee_id: employee.id,
      status: "pending",
      priority: "urgent",
      due_date: due_date,
      steps: steps,
      triggered_by: "hris_sync"
    }

    create_workflow(tenant, attrs)
  end

  @doc """
  Creates an incoming hardware workflow for a new asset.

  Uses the comprehensive incoming_hardware_template from Templates module.

  ## Examples

      iex> create_incoming_hardware_workflow("acme", asset, assigned_to: "it@company.com")
      {:ok, %Workflow{}}

  """
  def create_incoming_hardware_workflow(tenant, asset, opts \\ []) do
    due_date = Keyword.get(opts, :due_date, Date.add(Date.utc_today(), 3))
    assigned_to = Keyword.get(opts, :assigned_to)
    triggered_by = Keyword.get(opts, :triggered_by, "manual")

    template = Templates.from_template(:incoming_hardware, %{
      asset_id: asset.id,
      due_date: due_date,
      assigned_to: assigned_to,
      triggered_by: triggered_by,
      title: "Incoming Hardware: #{asset.name || asset.serial_number}"
    })

    create_workflow(tenant, template)
  end

  @doc """
  Creates a new employee onboarding workflow.

  Uses the comprehensive new_employee_onboarding_template from Templates module.

  ## Examples

      iex> create_new_employee_workflow("acme", employee, asset_id: 123)
      {:ok, %Workflow{}}

  """
  def create_new_employee_workflow(tenant, employee, opts \\ []) do
    due_date = Keyword.get(opts, :due_date, Date.add(Date.utc_today(), 7))
    asset_id = Keyword.get(opts, :asset_id)
    assigned_to = Keyword.get(opts, :assigned_to, "it@company.com")
    triggered_by = Keyword.get(opts, :triggered_by, "hris_sync")

    template = Templates.from_template(:new_employee, %{
      employee_id: employee.id,
      asset_id: asset_id,
      due_date: due_date,
      assigned_to: assigned_to,
      triggered_by: triggered_by,
      title: "New Employee Onboarding: #{employee.first_name} #{employee.last_name}"
    })

    create_workflow(tenant, template)
  end

  @doc """
  Creates an equipment return/offboarding workflow.

  Uses the equipment_return_template from Templates module.

  ## Examples

      iex> create_equipment_return_workflow("acme", employee, asset)
      {:ok, %Workflow{}}

  """
  def create_equipment_return_workflow(tenant, employee, asset, opts \\ []) do
    due_date = Keyword.get(opts, :due_date, Date.add(Date.utc_today(), 2))
    assigned_to = Keyword.get(opts, :assigned_to, "it@company.com")
    triggered_by = Keyword.get(opts, :triggered_by, "manual")

    template = Templates.from_template(:equipment_return, %{
      employee_id: employee.id,
      asset_id: asset.id,
      due_date: due_date,
      assigned_to: assigned_to,
      triggered_by: triggered_by,
      title: "Equipment Return: #{employee.first_name} #{employee.last_name} - #{asset.name}"
    })

    create_workflow(tenant, template)
  end

  @doc """
  Creates an emergency hardware replacement workflow.

  Uses the emergency_replacement_template from Templates module.

  ## Examples

      iex> create_emergency_replacement_workflow("acme", employee, failed_asset)
      {:ok, %Workflow{}}

  """
  def create_emergency_replacement_workflow(tenant, employee, asset, opts \\ []) do
    due_date = Keyword.get(opts, :due_date, Date.add(Date.utc_today(), 1))
    assigned_to = Keyword.get(opts, :assigned_to, "it@company.com")

    template = Templates.from_template(:emergency_replacement, %{
      employee_id: employee.id,
      asset_id: asset.id,
      due_date: due_date,
      assigned_to: assigned_to,
      triggered_by: "manual",
      title: "Emergency Replacement: #{employee.first_name} #{employee.last_name}"
    })

    create_workflow(tenant, template)
  end

  @doc """
  Creates a workflow from a template key.

  Generic function for creating workflows from any template.

  ## Examples

      iex> create_from_template("acme", :incoming_hardware, %{asset_id: 123})
      {:ok, %Workflow{}}

  """
  def create_from_template(tenant, template_key, attrs \\ %{}) do
    template = Templates.from_template(template_key, attrs)
    create_workflow(tenant, template)
  end

  @doc """
  Lists all available workflow templates.

  ## Examples

      iex> list_available_templates()
      [%{key: :incoming_hardware, name: "Incoming Hardware Setup", ...}, ...]

  """
  def list_available_templates do
    Templates.list_templates()
  end

  # Private functions

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:workflow_type, workflow_type}, query ->
        from(w in query, where: w.workflow_type == ^workflow_type)

      {:status, status}, query ->
        from(w in query, where: w.status == ^status)

      {:priority, priority}, query ->
        from(w in query, where: w.priority == ^priority)

      {:employee_id, employee_id}, query ->
        from(w in query, where: w.employee_id == ^employee_id)

      {:asset_id, asset_id}, query ->
        from(w in query, where: w.asset_id == ^asset_id)

      {:preload, preloads}, query ->
        from(w in query, preload: ^preloads)

      _, query ->
        query
    end)
  end

  defp broadcast_result({:ok, workflow} = result, tenant, event) do
    Phoenix.PubSub.broadcast(
      Assetronics.PubSub,
      "workflows:#{tenant}",
      {event, workflow}
    )

    # Send notifications based on the event type
    case event do
      "workflow_created" ->
        notify_workflow_created(tenant, workflow)

      "workflow_completed" ->
        notify_workflow_completed(tenant, workflow)

      "workflow_step_advanced" ->
        notify_workflow_step_advanced(tenant, workflow)

      _ ->
        :ok
    end

    result
  end

  defp broadcast_result(result, _tenant, _event), do: result

  # Send notification when workflow is created
  defp notify_workflow_created(tenant, workflow) do
    # Notify assigned_to person if specified
    if workflow.assigned_to do
      case Accounts.get_user_by_email(tenant, workflow.assigned_to) do
        %Accounts.User{} = user ->
          Notifications.notify(
            tenant,
            user.id,
            "workflow_assigned",
            %{
              title: "New workflow assigned",
              body: workflow.title || "A new workflow has been assigned to you",
              workflow_id: workflow.id,
              workflow_type: workflow.workflow_type,
              due_date: workflow.due_date
            }
          )
          Logger.info("Sent workflow creation notification to assigned user #{user.id} for workflow #{workflow.id}")

        nil ->
          Logger.warning("Could not send workflow notification: user not found for email #{workflow.assigned_to}")
      end
    end

    # Also notify the employee if this is employee-related workflow
    if workflow.employee_id do
      employee = Repo.get(Assetronics.Employees.Employee, workflow.employee_id, prefix: Triplex.to_prefix(tenant))

      if employee do
        case Accounts.get_user_by_email(tenant, employee.email) do
          %Accounts.User{} = user ->
            Notifications.notify(
              tenant,
              user.id,
              "workflow_created",
              %{
                title: "Workflow created",
                body: workflow.title || "A workflow has been created for you",
                workflow_id: workflow.id,
                workflow_type: workflow.workflow_type
              }
            )
            Logger.info("Sent workflow creation notification to employee #{user.id} for workflow #{workflow.id}")

          nil ->
            Logger.warning("Could not send workflow notification to employee: user not found for email #{employee.email}")
        end
      end
    end
  end

  # Send notification when workflow is completed
  defp notify_workflow_completed(tenant, workflow) do
    # Notify the employee if this is employee-related workflow
    if workflow.employee_id do
      employee = Repo.get(Assetronics.Employees.Employee, workflow.employee_id, prefix: Triplex.to_prefix(tenant))

      if employee do
        case Accounts.get_user_by_email(tenant, employee.email) do
          %Accounts.User{} = user ->
            Notifications.notify(
              tenant,
              user.id,
              "workflow_completed",
              %{
                title: "Workflow completed",
                body: "#{workflow.title || "Workflow"} has been completed",
                workflow_id: workflow.id,
                workflow_type: workflow.workflow_type
              }
            )
            Logger.info("Sent workflow completion notification to employee #{user.id} for workflow #{workflow.id}")

          nil ->
            Logger.warning("Could not send workflow completion notification: user not found for email #{employee.email}")
        end
      end
    end
  end

  # Send notification when workflow step is advanced
  defp notify_workflow_step_advanced(tenant, workflow) do
    # Notify assigned_to person about step progress
    if workflow.assigned_to do
      case Accounts.get_user_by_email(tenant, workflow.assigned_to) do
        %Accounts.User{} = user ->
          current_step_name = get_current_step_name(workflow)

          Notifications.notify(
            tenant,
            user.id,
            "workflow_step_advanced",
            %{
              title: "Workflow progress",
              body: "#{workflow.title}: #{current_step_name}",
              workflow_id: workflow.id,
              current_step: workflow.current_step
            }
          )
          Logger.info("Sent workflow step notification to assigned user #{user.id} for workflow #{workflow.id}")

        nil ->
          Logger.warning("Could not send workflow step notification: user not found for email #{workflow.assigned_to}")
      end
    end
  end

  # Helper to get current step name
  defp get_current_step_name(workflow) do
    if workflow.steps && workflow.current_step < length(workflow.steps) do
      step = Enum.at(workflow.steps, workflow.current_step)
      step["name"] || "Step #{workflow.current_step + 1}"
    else
      "Final step"
    end
  end
end
