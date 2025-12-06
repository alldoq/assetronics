defmodule AssetronicsWeb.OrganizationController do
  @moduledoc """
  Handles organization management.

  Endpoints:
  - GET /api/organizations - List all organizations
  - POST /api/organizations - Create organization
  - GET /api/organizations/:id - Get organization by ID
  - PUT /api/organizations/:id - Update organization
  - DELETE /api/organizations/:id - Delete organization
  """

  use AssetronicsWeb, :controller

  alias Assetronics.Organizations

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  Lists all organizations for the current tenant.
  Includes parent relationship in the response.
  """
  def index(conn, _params) do
    tenant = conn.assigns[:tenant]
    organizations = Organizations.list_organizations(tenant, preload: [:parent])

    conn
    |> put_status(:ok)
    |> render(:index, organizations: organizations)
  end

  @doc """
  Creates a new organization.
  """
  def create(conn, %{"organization" => organization_params}) do
    tenant = conn.assigns[:tenant]

    case Organizations.create_organization(tenant, organization_params) do
      {:ok, organization} ->
        # Reload with associations
        organization = Organizations.get_organization!(tenant, organization.id, preload: [:parent])

        conn
        |> put_status(:created)
        |> render(:show, organization: organization)

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
  Shows a specific organization.
  """
  def show(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    organization = Organizations.get_organization!(tenant, id, preload: [:parent, :children])

    conn
    |> put_status(:ok)
    |> render(:show, organization: organization)
  end

  @doc """
  Updates an organization.
  """
  def update(conn, %{"id" => id, "organization" => organization_params}) do
    tenant = conn.assigns[:tenant]
    organization = Organizations.get_organization!(tenant, id)

    case Organizations.update_organization(tenant, organization, organization_params) do
      {:ok, organization} ->
        # Reload with associations
        organization = Organizations.get_organization!(tenant, organization.id, preload: [:parent])

        conn
        |> put_status(:ok)
        |> render(:show, organization: organization)

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
  Deletes an organization.
  """
  def delete(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    organization = Organizations.get_organization!(tenant, id)

    case Organizations.delete_organization(tenant, organization) do
      {:ok, _organization} ->
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
