defmodule Assetronics.Employees do
  @moduledoc """
  The Employees context.

  Handles employee management and HRIS synchronization:
  - CRUD operations for employees
  - Syncing from external HRIS systems
  - Employee lifecycle (hire, termination)
  - Privacy-compliant PII handling (all encrypted)
  """

  import Ecto.Query, warn: false
  alias Assetronics.Repo
  alias Assetronics.Employees.Employee
  alias Assetronics.Accounts
  alias Assetronics.Notifications

  require Logger

  @doc """
  Returns the list of employees for a tenant.

  Optionally preloads organization, department, and location relationships.

  ## Examples

      iex> list_employees("acme")
      [%Employee{}, ...]

      iex> list_employees("acme", preload: [:organization, :department_rel, :office_location])
      [%Employee{organization: %Organization{}, ...}, ...]

  """
  def list_employees(tenant, opts \\ []) do
    query = from(e in Employee, order_by: [asc: e.email])

    query =
      if Keyword.get(opts, :preload) do
        from(e in query, preload: ^Keyword.get(opts, :preload))
      else
        query
      end

    query
    |> apply_filters(opts)
    |> then(&Repo.all(&1, prefix: Triplex.to_prefix(tenant)))
  end

  @doc """
  Gets a single employee.

  Raises `Ecto.NoResultsError` if the Employee does not exist.

  ## Examples

      iex> get_employee!("acme", "123")
      %Employee{}

      iex> get_employee!("acme", "123", preload: [:organization, :department_rel, :office_location])
      %Employee{organization: %Organization{}, ...}

  """
  def get_employee!(tenant, id, opts \\ []) do
    query = from(e in Employee, where: e.id == ^id)

    query =
      if Keyword.get(opts, :preload) do
        from(e in query, preload: ^Keyword.get(opts, :preload))
      else
        query
      end

    Repo.one!(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets an employee by email.

  ## Examples

      iex> get_employee_by_email("acme", "john@example.com")
      {:ok, %Employee{}}

  """
  def get_employee_by_email(tenant, email) do
    case Repo.one(from(e in Employee, where: e.email == ^email), prefix: Triplex.to_prefix(tenant)) do
      nil -> {:error, :not_found}
      employee -> {:ok, employee}
    end
  end

  @doc """
  Gets an employee by HRIS ID.

  ## Examples

      iex> get_employee_by_hris_id("acme", "EMP-123")
      {:ok, %Employee{}}

  """
  def get_employee_by_hris_id(tenant, hris_id) do
    case Repo.one(from(e in Employee, where: e.hris_id == ^hris_id), prefix: Triplex.to_prefix(tenant)) do
      nil -> {:error, :not_found}
      employee -> {:ok, employee}
    end
  end

  @doc """
  Creates an employee.

  ## Examples

      iex> create_employee("acme", %{email: "john@example.com"})
      {:ok, %Employee{}}

  """
  def create_employee(tenant, attrs \\ %{}) do
    %Employee{}
    |> Employee.changeset(attrs)
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "employee_created")
  end

  @doc """
  Updates an employee.

  ## Examples

      iex> update_employee("acme", employee, %{job_title: "Senior Engineer"})
      {:ok, %Employee{}}

  """
  def update_employee(tenant, %Employee{} = employee, attrs) do
    employee
    |> Employee.changeset(attrs)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "employee_updated")
  end

  @doc """
  Deletes an employee.

  ## Examples

      iex> delete_employee("acme", employee)
      {:ok, %Employee{}}

  """
  def delete_employee(tenant, %Employee{} = employee) do
    Repo.delete(employee, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking employee changes.

  ## Examples

      iex> change_employee(employee)
      %Ecto.Changeset{data: %Employee{}}

  """
  def change_employee(%Employee{} = employee, attrs \\ %{}) do
    Employee.changeset(employee, attrs)
  end

  @doc """
  Syncs or creates an employee from HRIS data.

  Uses upsert logic based on HRIS ID or email.

  ## Examples

      iex> sync_employee_from_hris("acme", %{hris_id: "123", email: "john@example.com", ...})
      {:ok, %Employee{}}

  """
  def sync_employee_from_hris(tenant, attrs) do
    start_time = System.monotonic_time()
    hris_id = Map.get(attrs, :hris_id) || Map.get(attrs, "hris_id")
    email = Map.get(attrs, :email) || Map.get(attrs, "email")
    source = Map.get(attrs, :source, "unknown")

    require Logger
    Logger.debug("Employees.sync_employee_from_hris: Looking up employee #{hris_id} / #{email}")

    result = case find_employee_for_sync(tenant, hris_id, email) do
      nil ->
        Logger.debug("Employees.sync_employee_from_hris: Employee not found, creating new.")
        # Create new employee
        try do
          %Employee{}
          |> Employee.sync_changeset(attrs)
          |> Repo.insert(prefix: Triplex.to_prefix(tenant))
          |> tap(fn
            {:ok, _} -> Logger.info("Employees.sync_employee_from_hris: Successfully created employee #{hris_id}")
            {:error, cs} -> Logger.error("Employees.sync_employee_from_hris: Failed to create employee #{hris_id}: #{inspect(cs.errors)}")
          end)
          |> broadcast_result(tenant, "employee_synced")
        rescue
          e ->
            Logger.error("Employees.sync_employee_from_hris: CRASH during insert for #{hris_id}: #{inspect(e)}")
            {:error, :crash}
        end

      employee ->
        Logger.debug("Employees.sync_employee_from_hris: Employee found (ID: #{employee.id}), updating.")
        # Update existing employee
        employee
        |> Employee.sync_changeset(attrs)
        |> Repo.update(prefix: Triplex.to_prefix(tenant))
        |> tap(fn
          {:ok, _} -> Logger.info("Employees.sync_employee_from_hris: Successfully updated employee #{hris_id}")
          {:error, cs} -> Logger.error("Employees.sync_employee_from_hris: Failed to update employee #{hris_id}: #{inspect(cs.errors)}")
        end)
        |> broadcast_result(tenant, "employee_synced")
    end

    # Emit telemetry
    duration = System.monotonic_time() - start_time
    case result do
      {:ok, _employee} ->
        :telemetry.execute(
          [:assetronics, :employees, :sync, :stop],
          %{duration: duration},
          %{tenant: tenant, source: source, status: :success}
        )
        :telemetry.execute(
          [:assetronics, :employees, :sync, :success],
          %{count: 1},
          %{tenant: tenant, source: source}
        )

      {:error, _reason} ->
        :telemetry.execute(
          [:assetronics, :employees, :sync, :stop],
          %{duration: duration},
          %{tenant: tenant, source: source, status: :failure}
        )
        :telemetry.execute(
          [:assetronics, :employees, :sync, :failure],
          %{count: 1},
          %{tenant: tenant, source: source}
        )
    end

    result
  end

  @doc """
  Terminates an employee.

  Sets employment status to terminated and records termination date.

  ## Examples

      iex> terminate_employee("acme", employee, ~D[2024-12-31])
      {:ok, %Employee{}}

  """
  def terminate_employee(tenant, %Employee{} = employee, termination_date \\ nil) do
    termination_date = termination_date || Date.utc_today()

    employee
    |> Employee.changeset(%{
      employment_status: "terminated",
      termination_date: termination_date
    })
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "employee_terminated")
  end

  @doc """
  Lists active employees.

  ## Examples

      iex> list_active_employees("acme")
      [%Employee{}, ...]

  """
  def list_active_employees(tenant) do
    query = from(e in Employee, where: e.employment_status == "active")
    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Lists employees by department.

  ## Examples

      iex> list_employees_by_department("acme", "Engineering")
      [%Employee{}, ...]

  """
  def list_employees_by_department(tenant, department) do
    query = from(e in Employee, where: e.department == ^department)
    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Search employees by name or email.

  ## Examples

      iex> search_employees("acme", "john")
      [%Employee{}, ...]

  """
  def search_employees(tenant, search_query) do
    # Note: Can't search encrypted fields directly, so we search email only
    search_term = "%#{search_query}%"

    query =
      from e in Employee,
        where: ilike(e.email, ^search_term) or ilike(e.job_title, ^search_term),
        order_by: [asc: e.email]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets employees with assets assigned.

  ## Examples

      iex> list_employees_with_assets("acme")
      [%Employee{assets: [...]}, ...]

  """
  def list_employees_with_assets(tenant) do
    query =
      from e in Employee,
        join: a in assoc(e, :assets),
        where: a.status == "assigned",
        preload: [assets: a],
        distinct: true

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Terminates an employee.

  Sets employment_status to "terminated" and records termination details.
  """
  def terminate_employee(tenant, %Employee{} = employee, termination_date, reason, notes) do
    attrs = %{
      employment_status: "terminated",
      termination_date: termination_date,
      termination_reason: reason,
      notes: notes
    }

    employee
    |> Employee.changeset(attrs)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "employee_terminated")
  end

  @doc """
  Reactivates a terminated employee.

  Sets employment_status back to "active" and clears termination details.
  """
  def reactivate_employee(tenant, %Employee{} = employee) do
    attrs = %{
      employment_status: "active",
      termination_date: nil,
      termination_reason: nil
    }

    employee
    |> Employee.changeset(attrs)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "employee_reactivated")
  end

  @doc """
  Gets an employee with their assigned assets preloaded.
  """
  def get_employee_with_assets(tenant, employee_id) do
    query =
      from e in Employee,
        where: e.id == ^employee_id,
        left_join: a in assoc(e, :assets),
        where: is_nil(a.id) or a.status == "assigned",
        preload: [assets: a]

    Repo.one(query, prefix: Triplex.to_prefix(tenant))
  end

  # Private functions

  defp find_employee_for_sync(tenant, hris_id, email) when not is_nil(hris_id) do
    query = from(e in Employee,
      where: e.hris_id == ^hris_id or e.email == ^email
    )
    Repo.one(query, prefix: Triplex.to_prefix(tenant))
  end

  defp find_employee_for_sync(tenant, _hris_id, email) when not is_nil(email) do
    Repo.one(from(e in Employee, where: e.email == ^email), prefix: Triplex.to_prefix(tenant))
  end

  defp find_employee_for_sync(_tenant, _hris_id, _email), do: nil

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:employment_status, status}, query ->
        from(e in query, where: e.employment_status == ^status)

      {:department, department}, query ->
        from(e in query, where: e.department == ^department)

      {:preload, preloads}, query ->
        from(e in query, preload: ^preloads)

      _, query ->
        query
    end)
  end

  defp broadcast_result({:ok, employee} = result, tenant, event) do
    Phoenix.PubSub.broadcast(
      Assetronics.PubSub,
      "employees:#{tenant}",
      {event, employee}
    )

    # Send notifications based on the event type
    case event do
      "employee_synced" ->
        notify_employee_synced(tenant, employee)

      "employee_terminated" ->
        notify_employee_terminated(tenant, employee)

      _ ->
        :ok
    end

    result
  end

  defp broadcast_result(result, _tenant, _event), do: result

  # Send notification when employee is synced from HRIS
  defp notify_employee_synced(tenant, employee) do
    # Notify admins about new employee sync
    admin_users = Accounts.list_users_by_role(tenant, "admin")
    super_admin_users = Accounts.list_users_by_role(tenant, "super_admin")
    all_admins = admin_users ++ super_admin_users

    # Check if this is a new employee (recently hired)
    is_new_hire = employee.hire_date && Date.diff(Date.utc_today(), employee.hire_date) <= 30

    if is_new_hire && length(all_admins) > 0 do
      Enum.each(all_admins, fn admin ->
        Notifications.notify(
          tenant,
          admin.id,
          "employee_synced",
          %{
            title: "New employee synced",
            body: "#{employee.first_name} #{employee.last_name} has been synced from HRIS",
            employee_id: employee.id,
            employee_name: "#{employee.first_name} #{employee.last_name}",
            hire_date: employee.hire_date
          }
        )
      end)

      Logger.info("Sent new employee sync notifications to #{length(all_admins)} admins for employee #{employee.id}")
    end
  end

  # Send notification when employee is terminated
  defp notify_employee_terminated(tenant, employee) do
    # Notify admins about employee termination
    admin_users = Accounts.list_users_by_role(tenant, "admin")
    super_admin_users = Accounts.list_users_by_role(tenant, "super_admin")
    all_admins = admin_users ++ super_admin_users

    Enum.each(all_admins, fn admin ->
      Notifications.notify(
        tenant,
        admin.id,
        "employee_terminated",
        %{
          title: "Employee terminated",
          body: "#{employee.first_name} #{employee.last_name} has been terminated",
          employee_id: employee.id,
          employee_name: "#{employee.first_name} #{employee.last_name}",
          termination_date: employee.termination_date
        }
      )
    end)

    Logger.info("Sent employee termination notifications to #{length(all_admins)} admins for employee #{employee.id}")
  end
end
