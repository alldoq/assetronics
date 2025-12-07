defmodule AssetronicsWeb.SoftwareController do
  use AssetronicsWeb, :controller

  alias Assetronics.Software
  alias Assetronics.Software.License

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  List all software licenses for the tenant.
  """
  def index(conn, _params) do
    tenant = conn.assigns[:tenant]
    licenses = Software.list_licenses(tenant)

    # Enrich each license with assigned_count
    licenses_with_counts = Enum.map(licenses, fn license ->
      assigned_count = Software.count_active_assignments(tenant, license.id)
      Map.put(license, :assigned_count, assigned_count)
    end)

    render(conn, :index, licenses: licenses_with_counts)
  end

  @doc """
  Create a new software license.
  """
  def create(conn, %{"software" => license_params}) do
    tenant = conn.assigns[:tenant]

    with {:ok, %License{} = license} <- Software.create_license(tenant, license_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/v1/software/#{license.id}")
      |> render(:show, license: license)
    end
  end

  @doc """
  Get a single software license by ID.
  """
  def show(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    license = Software.get_license!(tenant, id)
    render(conn, :show, license: license)
  end

  @doc """
  Update a software license.
  """
  def update(conn, %{"id" => id, "software" => license_params}) do
    tenant = conn.assigns[:tenant]
    license = Software.get_license!(tenant, id)

    with {:ok, %License{} = license} <- Software.update_license(tenant, license, license_params) do
      render(conn, :show, license: license)
    end
  end

  @doc """
  Delete a software license.
  """
  def delete(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    license = Software.get_license!(tenant, id)

    with {:ok, %License{}} <- Software.delete_license(tenant, license) do
      send_resp(conn, :no_content, "")
    end
  end

  @doc """
  Assign a software license to an employee.
  """
  def assign(conn, %{"software_id" => id, "employee_id" => employee_id}) do
    tenant = conn.assigns[:tenant]

    with {:ok, assignment} <- Software.assign_software(tenant, employee_id, id) do
      conn
      |> put_status(:created)
      |> render(:assignment, assignment: assignment)
    end
  end

  @doc """
  Revoke a software license assignment.
  """
  def revoke(conn, %{"software_id" => license_id, "assignment_id" => assignment_id}) do
    tenant = conn.assigns[:tenant]

    with {:ok, _} <- Software.revoke_assignment(tenant, assignment_id) do
      send_resp(conn, :no_content, "")
    end
  end

  @doc """
  Get all assignments for a software license.
  """
  def assignments(conn, %{"software_id" => id}) do
    tenant = conn.assigns[:tenant]
    assignments = Software.list_assignments(tenant, id)
    render(conn, :assignments, assignments: assignments)
  end

  @doc """
  Get statistics for a software license.
  """
  def stats(conn, %{"software_id" => id}) do
    tenant = conn.assigns[:tenant]
    stats = Software.get_license_stats(tenant, id)
    render(conn, :stats, stats: stats)
  end

  @doc """
  Get licenses expiring within a specified number of days.
  """
  def expiring(conn, params) do
    tenant = conn.assigns[:tenant]
    days = String.to_integer(params["days"] || "30")
    licenses = Software.list_expiring_licenses(tenant, days)
    render(conn, :index, licenses: licenses)
  end

  @doc """
  Get underutilized licenses.
  """
  def underutilized(conn, params) do
    tenant = conn.assigns[:tenant]
    threshold = String.to_integer(params["threshold"] || "50")
    licenses = Software.list_underutilized_licenses(tenant, threshold)
    render(conn, :index, licenses: licenses)
  end

  # Private helpers

  defp build_filters(params) do
    Enum.reduce(params, [], fn
      {"status", value}, acc when value != "" ->
        [{:status, value} | acc]

      {"vendor", value}, acc when value != "" ->
        [{:vendor, value} | acc]

      {"search", value}, acc when value != "" ->
        [{:search, value} | acc]

      _, acc ->
        acc
    end)
  end
end
