defmodule Assetronics.Reports.LicenseReclamation do
  @moduledoc """
  Generates License Reclamation Report.
  Identifies software licenses assigned to users who haven't logged in for X days.
  """

  import Ecto.Query
  alias Assetronics.Repo
  alias Assetronics.Software.License
  alias Assetronics.Software.Assignment
  alias Assetronics.Employees.Employee
  alias Triplex

  def generate(tenant, days_threshold \\ 90) do
    threshold_date = DateTime.utc_now() |> DateTime.add(-days_threshold, :day) |> DateTime.to_naive()

    # Query:
    # Select Assignments
    # Join License (to get name, cost)
    # Join Employee (to get name, last_login_at)
    # Where Employee.last_login_at < threshold OR (last_login_at IS NULL AND assigned_at < threshold)

    query = from a in Assignment,
      join: l in License, on: a.software_license_id == l.id,
      join: e in Employee, on: a.employee_id == e.id,
      where: a.status == "active",
      where: e.employment_status == "active",
      where: (e.last_login_at < ^threshold_date) or (is_nil(e.last_login_at) and a.inserted_at < ^threshold_date),
      select: %{
        employee_name: fragment("concat(?, ' ', ?)", e.first_name, e.last_name),
        employee_email: e.email,
        license_name: l.name,
        vendor: l.vendor,
        cost: l.cost_per_seat_encrypted, # We need to decrypt this in application layer usually, but let's select it
        last_login: e.last_login_at,
        days_inactive: fragment("EXTRACT(DAY FROM ? - ?)", ^DateTime.utc_now(), e.last_login_at)
      }

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
    |> Enum.map(fn row ->
        # Decrypt cost if needed, but for MVP we might just show count
        Map.put(row, :status, "reclaimable")
    end)
  end
end
