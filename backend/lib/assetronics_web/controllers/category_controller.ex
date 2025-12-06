defmodule AssetronicsWeb.CategoryController do
  @moduledoc """
  Handles asset category management.

  Endpoints:
  - GET /api/categories - List all categories
  - POST /api/categories - Create category
  - GET /api/categories/:id - Get category by ID
  - PUT /api/categories/:id - Update category
  - DELETE /api/categories/:id - Delete category
  """

  use AssetronicsWeb, :controller

  alias Assetronics.Categories

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  Lists all categories for the current tenant.
  """
  def index(conn, _params) do
    tenant = conn.assigns[:tenant]
    categories = Categories.list_categories(tenant)

    conn
    |> put_status(:ok)
    |> render(:index, categories: categories)
  end

  @doc """
  Creates a new category.
  """
  def create(conn, %{"category" => category_params}) do
    tenant = conn.assigns[:tenant]

    case Categories.create_category(tenant, category_params) do
      {:ok, category} ->
        conn
        |> put_status(:created)
        |> render(:show, category: category)

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
  Shows a specific category.
  """
  def show(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    category = Categories.get_category!(tenant, id)

    conn
    |> put_status(:ok)
    |> render(:show, category: category)
  end

  @doc """
  Updates a category.
  """
  def update(conn, %{"id" => id, "category" => category_params}) do
    tenant = conn.assigns[:tenant]
    category = Categories.get_category!(tenant, id)

    case Categories.update_category(tenant, category, category_params) do
      {:ok, category} ->
        conn
        |> put_status(:ok)
        |> render(:show, category: category)

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
  Deletes a category.
  """
  def delete(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]
    category = Categories.get_category!(tenant, id)

    case Categories.delete_category(tenant, category) do
      {:ok, _category} ->
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
