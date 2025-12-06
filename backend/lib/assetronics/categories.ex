defmodule Assetronics.Categories do
  @moduledoc """
  The Categories context.

  Handles asset category management:
  - CRUD operations for categories
  - Category listing and retrieval
  - Tenant-specific category organization
  """

  import Ecto.Query, warn: false
  alias Assetronics.Repo
  alias Assetronics.Categories.Category

  @doc """
  Returns the list of categories for a tenant.

  ## Examples

      iex> list_categories("acme")
      [%Category{}, ...]

  """
  def list_categories(tenant) do
    query = from(c in Category, order_by: [asc: c.name])
    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Category does not exist.

  ## Examples

      iex> get_category!("acme", "123")
      %Category{}

  """
  def get_category!(tenant, id) do
    Repo.get!(Category, id, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets a category by name.

  Returns `nil` if no category with that name exists.

  ## Examples

      iex> get_category_by_name("acme", "Computers")
      %Category{}

  """
  def get_category_by_name(tenant, name) do
    query = from(c in Category, where: c.name == ^name)
    Repo.one(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Creates a category.

  ## Examples

      iex> create_category("acme", %{name: "Computers"})
      {:ok, %Category{}}

  """
  def create_category(tenant, attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "category_created")
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category("acme", category, %{name: "New Name"})
      {:ok, %Category{}}

  """
  def update_category(tenant, %Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "category_updated")
  end

  @doc """
  Deletes a category.

  ## Examples

      iex> delete_category("acme", category)
      {:ok, %Category{}}

  """
  def delete_category(tenant, %Category{} = category) do
    Repo.delete(category, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{data: %Category{}}

  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  # Private functions

  defp broadcast_result({:ok, category} = result, tenant, event) do
    Phoenix.PubSub.broadcast(
      Assetronics.PubSub,
      "categories:#{tenant}",
      {event, category}
    )

    result
  end

  defp broadcast_result(result, _tenant, _event), do: result
end
