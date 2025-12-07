defmodule Assetronics.Software do
  @moduledoc """
  The Software context.
  
  Handles management of software licenses and subscriptions.
  """

  import Ecto.Query, warn: false
  alias Assetronics.Repo
  alias Assetronics.Software.License
  alias Triplex

  alias Assetronics.Software.Assignment

  @doc "Returns the list of software licenses for a tenant."
  def list_licenses(tenant) do
    Repo.all(License, prefix: Triplex.to_prefix(tenant))
  end

  @doc "Gets a single license."
  def get_license!(tenant, id) do
    Repo.get!(License, id, prefix: Triplex.to_prefix(tenant))
  end

  @doc "Creates a license."
  def create_license(tenant, attrs \\ %{}) do
    %License{}
    |> License.changeset(attrs)
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
  end

  @doc "Updates a license."
  def update_license(tenant, %License{} = license, attrs) do
    license
    |> License.changeset(attrs)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
  end

  @doc "Deletes a license."
  def delete_license(tenant, %License{} = license) do
    Repo.delete(license, prefix: Triplex.to_prefix(tenant))
  end

  @doc "Returns an `%Ecto.Changeset{}` for tracking license changes."
  def change_license(%License{} = license, attrs \\ %{}) do
    License.changeset(license, attrs)
  end

  @doc "Assigns software to an employee."
  def assign_software(tenant, employee_id, license_id, attrs \\ %{}) do
    %Assignment{}
    |> Assignment.changeset(Map.merge(attrs, %{employee_id: employee_id, software_license_id: license_id}))
    |> Repo.insert(prefix: Triplex.to_prefix(tenant), on_conflict: :nothing)
  end

  @doc "Lists assignments for a license."
  def list_assignments(tenant, license_id) do
    query = from a in Assignment,
      where: a.software_license_id == ^license_id,
      preload: [:employee]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc "Lists all active assignments for an employee."
  def list_employee_assignments(tenant, employee_id) do
    query = from a in Assignment,
      where: a.employee_id == ^employee_id and a.status == "active",
      preload: [:software_license]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc "Revokes a software assignment (sets status to 'revoked')."
  def revoke_assignment(tenant, assignment_id) do
    assignment = Repo.get!(Assignment, assignment_id, prefix: Triplex.to_prefix(tenant))

    assignment
    |> Assignment.changeset(%{status: "revoked"})
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
  end

  @doc "Revokes all active software assignments for an employee."
  def revoke_employee_licenses(tenant, employee_id) do
    query = from a in Assignment,
      where: a.employee_id == ^employee_id and a.status == "active"

    assignments = Repo.all(query, prefix: Triplex.to_prefix(tenant))

    Enum.map(assignments, fn assignment ->
      assignment
      |> Assignment.changeset(%{status: "revoked"})
      |> Repo.update(prefix: Triplex.to_prefix(tenant))
    end)
  end

  @doc "Gets available licenses by category or vendor."
  def list_available_licenses(tenant, opts \\ []) do
    query = from l in License,
      where: l.status == "active"

    query = if vendor = opts[:vendor] do
      from l in query, where: l.vendor == ^vendor
    else
      query
    end

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc "Checks if a license has available seats."
  def available_seats?(tenant, license_id) do
    license = get_license!(tenant, license_id)
    assigned_count = count_active_assignments(tenant, license_id)

    license.total_seats > assigned_count
  end

  @doc "Counts active assignments for a license."
  def count_active_assignments(tenant, license_id) do
    query = from a in Assignment,
      where: a.software_license_id == ^license_id and a.status == "active",
      select: count(a.id)

    Repo.one(query, prefix: Triplex.to_prefix(tenant)) || 0
  end

  @doc "Auto-assigns software licenses based on employee role or department."
  def auto_assign_licenses_for_employee(tenant, employee_id, opts \\ []) do
    # Get employee to check role/department
    employee = Assetronics.Employees.get_employee!(tenant, employee_id)

    # Get default licenses for role (could be configured via settings)
    # For now, we'll assign based on department or manual license list
    license_ids = opts[:license_ids] || []

    Enum.map(license_ids, fn license_id ->
      if available_seats?(tenant, license_id) do
        assign_software(tenant, employee_id, license_id, %{
          assigned_at: Date.utc_today(),
          status: "active"
        })
      else
        {:error, :no_seats_available}
      end
    end)
  end

  @doc "Returns usage statistics for a license."
  def get_license_stats(tenant, license_id) do
    license = get_license!(tenant, license_id)
    active_count = count_active_assignments(tenant, license_id)

    %{
      license_id: license_id,
      license_name: license.name,
      total_seats: license.total_seats,
      used_seats: active_count,
      available_seats: license.total_seats - active_count,
      utilization_rate: if(license.total_seats > 0, do: active_count / license.total_seats * 100, else: 0),
      cost_per_seat: license.cost_per_seat,
      annual_cost: license.annual_cost,
      status: license.status,
      expiration_date: license.expiration_date
    }
  end

  @doc "Returns all licenses expiring soon (within given days)."
  def list_expiring_licenses(tenant, days \\ 30) do
    expiration_threshold = Date.add(Date.utc_today(), days)

    query = from l in License,
      where: l.status == "active" and l.expiration_date <= ^expiration_threshold,
      order_by: [asc: l.expiration_date]

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc "Returns underutilized licenses (below threshold percentage)."
  def list_underutilized_licenses(tenant, threshold_percentage \\ 50) do
    licenses = list_licenses(tenant)

    Enum.filter(licenses, fn license ->
      stats = get_license_stats(tenant, license.id)
      stats.utilization_rate < threshold_percentage
    end)
  end
end
