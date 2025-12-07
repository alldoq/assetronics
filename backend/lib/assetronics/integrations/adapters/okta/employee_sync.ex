defmodule Assetronics.Integrations.Adapters.Okta.EmployeeSync do
  @moduledoc """
  Handles employee synchronization logic for Okta integration.

  Manages the sync process, workflow creation, termination handling,
  and sync result tracking.
  """

  alias Assetronics.Employees
  alias Assetronics.Workflows
  alias Assetronics.Integrations.Adapters.Okta.DataMapper

  require Logger

  @doc """
  Syncs all employees from Okta data.

  Returns sync statistics including created, updated, terminated counts.
  """
  def sync_employees(tenant, users_data, integration) do
    # Debug: Log the first user to check field names
    if List.first(users_data) do
      Logger.info("Sample Okta user data: #{inspect(List.first(users_data))}")
    end

    results = %{
      total: length(users_data),
      created: 0,
      updated: 0,
      terminated: 0,
      errors: 0,
      workflows_created: 0
    }

    users_data
    |> Enum.reduce(results, fn user_data, acc ->
      case sync_employee(tenant, user_data, integration) do
        {:ok, :created, workflow_created?} ->
          acc
          |> Map.update!(:created, &(&1 + 1))
          |> maybe_increment_workflows(workflow_created?)

        {:ok, :updated, workflow_created?} ->
          acc
          |> Map.update!(:updated, &(&1 + 1))
          |> maybe_increment_workflows(workflow_created?)

        {:ok, :terminated, _} ->
          Map.update!(acc, :terminated, &(&1 + 1))

        {:error, _reason} ->
          Map.update!(acc, :errors, &(&1 + 1))
      end
    end)
    |> then(&{:ok, &1})
  end

  @doc """
  Syncs a single employee from Okta data.

  Handles creation, updates, termination, and workflow creation.
  """
  def sync_employee(tenant, user_data, integration) do
    attrs = DataMapper.map_employee_attrs(tenant, user_data)
    hris_id = to_string(user_data["id"])

    # Check if user should be terminated
    is_terminated = DataMapper.is_terminated?(user_data)
    status = user_data["status"]

    Logger.debug("Syncing user #{hris_id} (#{attrs[:email]}). Okta status: #{status}. Terminated: #{is_terminated}")

    case Employees.sync_employee_from_hris(tenant, attrs) do
      {:ok, employee} ->
        workflow_created? = maybe_create_workflow(tenant, employee, user_data, integration)

        # Handle termination if needed
        action = cond do
          is_terminated && employee.employment_status == "active" ->
            terminate_employee(tenant, employee, user_data)
            :terminated

          true ->
            if employee.inserted_at == employee.updated_at, do: :created, else: :updated
        end

        {:ok, action, workflow_created?}

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
          Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
            opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
          end)
        end)
        Logger.error("Validation failed for user #{hris_id}: #{inspect(errors)}")
        {:error, :validation_failed}

      {:error, reason} ->
        Logger.error("Failed to sync user #{hris_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Creates an onboarding workflow for new hires if applicable.

  Only creates workflows for employees hired within the last 30 days or in the future.
  Uses the activated date if hire_date is not available.
  """
  def maybe_create_workflow(tenant, employee, user_data, integration) do
    profile = user_data["profile"] || %{}
    hire_date = DataMapper.parse_date(
      DataMapper.get_value(profile, "hireDate") || user_data["activated"]
    )
    today = Date.utc_today()

    if hire_date do
      diff = Date.diff(today, hire_date)

      Logger.debug("Checking workflow for #{employee.email}: Hire Date #{hire_date}, Today #{today}, Diff #{diff} days")

      # Only create workflow if hired in last 30 days (or future)
      if diff <= 30 do
        Logger.info("Creating onboarding workflow for #{employee.email} (Hired: #{hire_date})")
        case Workflows.create_onboarding_workflow(tenant, employee, nil,
              triggered_by: "hris_sync",
              integration_id: integration.id) do
          {:ok, _workflow} -> true
          {:error, reason} ->
            Logger.error("Failed to create workflow: #{inspect(reason)}")
            false
        end
      else
        Logger.debug("Skipping workflow: Hire date #{hire_date} is too old (> 30 days ago)")
        false
      end
    else
      Logger.debug("Skipping workflow: No hire date found")
      false
    end
  end

  # Private functions

  defp terminate_employee(tenant, employee, user_data) do
    # Use statusChanged date if available, otherwise use today
    termination_date = DataMapper.parse_date(user_data["statusChanged"]) || Date.utc_today()
    Employees.terminate_employee(tenant, employee, termination_date, "Synced from Okta (status: #{user_data["status"]})", nil)
  end

  defp maybe_increment_workflows(acc, true), do: Map.update!(acc, :workflows_created, &(&1 + 1))
  defp maybe_increment_workflows(acc, false), do: acc
end