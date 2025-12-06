defmodule AssetronicsWeb.DepartmentController do
  @moduledoc """
  Handles department management.

  Endpoints:
  - GET /api/departments - List all departments
  - POST /api/departments - Create department
  - GET /api/departments/:id - Get department by ID
  - PUT /api/departments/:id - Update department
  - DELETE /api/departments/:id - Delete department
  """

  use AssetronicsWeb, :controller

  alias Assetronics.Departments

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  Lists all departments for the current tenant.
  Includes parent relationship in the response.
  """
  def index(conn, _params) do
    tenant = conn.assigns[:tenant]
    departments = Departments.list_departments(tenant, preload: [:parent])

    conn
    |> put_status(:ok)
    |> render(:index, departments: departments)
  end

  @doc """
  Creates a new department.
  """
  def create(conn, %{"department" => department_params}) do
    tenant = conn.assigns[:tenant]

    case Departments.create_department(tenant, department_params) do
      {:ok, department} ->
        # Reload with associations
        department = Departments.get_department!(tenant, department.id, preload: [:parent])

        conn
        |> put_status(:created)
        |> render(:show, department: department)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(AssetronicsWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid request format"})
  end

  @doc """
  Shows a specific department.
  """
  def show(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    department = Departments.get_department!(tenant, id, preload: [:parent, :children])

    conn
    |> put_status(:ok)
    |> render(:show, department: department)
  end

  @doc """
  Updates a department.
  """
  def update(conn, %{"id" => id, "department" => department_params}) do
    tenant = conn.assigns[:tenant]
    department = Departments.get_department!(tenant, id)

    case Departments.update_department(tenant, department, department_params) do
      {:ok, department} ->
        # Reload with associations
        department = Departments.get_department!(tenant, department.id, preload: [:parent])

        conn
        |> put_status(:ok)
        |> render(:show, department: department)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(AssetronicsWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)
    end
  end

  def update(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid request format"})
  end

  @doc """
  Deletes a department.
  """
  def delete(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    department = Departments.get_department!(tenant, id)

    case Departments.delete_department(tenant, department) do
      {:ok, _department} ->
        conn
        |> send_resp(:no_content, "")

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(AssetronicsWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)
    end
  end
end
