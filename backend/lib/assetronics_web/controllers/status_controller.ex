defmodule AssetronicsWeb.StatusController do
  @moduledoc """
  Handles asset status management.

  Endpoints:
  - GET /api/statuses - List all statuses
  - POST /api/statuses - Create status
  - GET /api/statuses/:id - Get status by ID
  - PUT /api/statuses/:id - Update status
  - DELETE /api/statuses/:id - Delete status
  """

  use AssetronicsWeb, :controller

  alias Assetronics.Statuses

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  Lists all statuses for the current tenant.
  """
  def index(conn, _params) do
    tenant = conn.assigns[:tenant]
    statuses = Statuses.list_statuses(tenant)

    conn
    |> put_status(:ok)
    |> render(:index, statuses: statuses)
  end

  @doc """
  Creates a new status.
  """
  def create(conn, %{"status" => status_params}) do
    tenant = conn.assigns[:tenant]

    case Statuses.create_status(tenant, status_params) do
      {:ok, status} ->
        conn
        |> put_status(:created)
        |> render(:show, status: status)

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
  Shows a specific status.
  """
  def show(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    status = Statuses.get_status!(tenant, id)

    conn
    |> put_status(:ok)
    |> render(:show, status: status)
  end

  @doc """
  Updates a status.
  """
  def update(conn, %{"id" => id, "status" => status_params}) do
    tenant = conn.assigns[:tenant]
    status = Statuses.get_status!(tenant, id)

    case Statuses.update_status(tenant, status, status_params) do
      {:ok, status} ->
        conn
        |> put_status(:ok)
        |> render(:show, status: status)

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
  Deletes a status.
  """
  def delete(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    status = Statuses.get_status!(tenant, id)

    case Statuses.delete_status(tenant, status) do
      {:ok, _status} ->
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
