defmodule Assetronics.Departments do
  @moduledoc """
  The Departments context.

  Handles department management:
  - CRUD operations for departments
  - Hierarchical department structures
  - Parent-child relationships
  - Tenant-specific department organization
  """

  import Ecto.Query, warn: false
  alias Assetronics.Repo
  alias Assetronics.Departments.Department

  @doc """
  Returns the list of departments for a tenant.

  Optionally preloads parent and children relationships.

  ## Examples

      iex> list_departments("acme")
      [%Department{}, ...]

      iex> list_departments("acme", preload: [:parent, :children])
      [%Department{parent: %Department{}, children: [...]}, ...]

  """
  def list_departments(tenant, opts \\ []) do
    query = from(d in Department, order_by: [asc: d.name])

    query =
      if Keyword.get(opts, :preload) do
        from(d in query, preload: ^Keyword.get(opts, :preload))
      else
        query
      end

    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets a single department.

  Raises `Ecto.NoResultsError` if the Department does not exist.

  ## Examples

      iex> get_department!("acme", "123")
      %Department{}

  """
  def get_department!(tenant, id, opts \\ []) do
    query = from(d in Department, where: d.id == ^id)

    query =
      if Keyword.get(opts, :preload) do
        from(d in query, preload: ^Keyword.get(opts, :preload))
      else
        query
      end

    Repo.one!(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets a department by name.

  Returns `{:ok, department}` if found, `{:error, :not_found}` otherwise.

  ## Examples

      iex> get_department_by_name("acme", "Engineering")
      {:ok, %Department{}}

      iex> get_department_by_name("acme", "Non Existent")
      {:error, :not_found}

  """
  def get_department_by_name(tenant, name) do
    query = from(d in Department, where: d.name == ^name)
    case Repo.one(query, prefix: Triplex.to_prefix(tenant)) do
      nil -> {:error, :not_found}
      department -> {:ok, department}
    end
  end

  @doc """
  Gets a department by normalized name or creates it if it doesn't exist.

  Normalizes the name by trimming whitespace and converting to title case
  to prevent duplicates like "Engineering" vs "engineering" vs "  engineering  ".

  ## Examples

      iex> get_or_create_department("acme", "Engineering")
      {:ok, %Department{name: "Engineering"}}

      iex> get_or_create_department("acme", "  engineering  ")
      {:ok, %Department{name: "Engineering"}}  # Same department as above

  """
  def get_or_create_department(tenant, name) when is_binary(name) do
    normalized_name = normalize_name(name)

    # Try to find existing department (case-insensitive)
    query = from d in Department,
      where: fragment("LOWER(?)", d.name) == ^String.downcase(normalized_name)

    case Repo.one(query, prefix: Triplex.to_prefix(tenant)) do
      nil ->
        # Create new department with normalized name
        create_department(tenant, %{name: normalized_name})

      existing ->
        {:ok, existing}
    end
  end

  @doc """
  Creates a department.

  ## Examples

      iex> create_department("acme", %{name: "Engineering", type: "department"})
      {:ok, %Department{}}

  """
  def create_department(tenant, attrs \\ %{}) do
    %Department{}
    |> Department.changeset(attrs)
    |> validate_no_circular_reference(tenant)
    |> Repo.insert(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "department_created")
  end

  @doc """
  Updates a department.

  ## Examples

      iex> update_department("acme", department, %{name: "New Name"})
      {:ok, %Department{}}

  """
  def update_department(tenant, %Department{} = department, attrs) do
    department
    |> Department.changeset(attrs)
    |> validate_no_circular_reference(tenant)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "department_updated")
  end

  @doc """
  Deletes a department.

  ## Examples

      iex> delete_department("acme", department)
      {:ok, %Department{}}

  """
  def delete_department(tenant, %Department{} = department) do
    Repo.delete(department, prefix: Triplex.to_prefix(tenant))
    |> broadcast_result(tenant, "department_deleted")
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking department changes.

  ## Examples

      iex> change_department(department)
      %Ecto.Changeset{data: %Department{}}

  """
  def change_department(%Department{} = department, attrs \\ %{}) do
    Department.changeset(department, attrs)
  end

  @doc """
  Gets all root departments (departments without a parent).

  ## Examples

      iex> list_root_departments("acme")
      [%Department{}, ...]

  """
  def list_root_departments(tenant) do
    query = from(d in Department, where: is_nil(d.parent_id), order_by: [asc: d.name])
    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets all children of a department.

  ## Examples

      iex> list_children("acme", parent_id)
      [%Department{}, ...]

  """
  def list_children(tenant, parent_id) do
    query = from(d in Department, where: d.parent_id == ^parent_id, order_by: [asc: d.name])
    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  # Private functions

  defp normalize_name(name) when is_binary(name) do
    name
    |> String.trim()
    |> String.split(~r/\s+/)
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp validate_no_circular_reference(changeset, tenant) do
    # Check if setting a parent would create a circular reference
    case Ecto.Changeset.fetch_change(changeset, :parent_id) do
      {:ok, nil} ->
        changeset

      {:ok, parent_id} ->
        dept_id = Ecto.Changeset.get_field(changeset, :id)

        if dept_id && would_create_circular_reference?(tenant, dept_id, parent_id) do
          Ecto.Changeset.add_error(
            changeset,
            :parent_id,
            "would create a circular reference"
          )
        else
          changeset
        end

      :error ->
        changeset
    end
  end

  defp would_create_circular_reference?(tenant, dept_id, parent_id) do
    # Check if parent_id is a descendant of dept_id
    # If so, setting parent_id as parent would create a cycle
    is_descendant?(tenant, parent_id, dept_id)
  end

  defp is_descendant?(tenant, potential_descendant_id, ancestor_id) do
    query =
      from(d in Department,
        where: d.id == ^potential_descendant_id,
        select: d.parent_id
      )

    case Repo.one(query, prefix: Triplex.to_prefix(tenant)) do
      nil ->
        false

      ^ancestor_id ->
        true

      parent_id ->
        is_descendant?(tenant, parent_id, ancestor_id)
    end
  end

  defp broadcast_result({:ok, department} = result, tenant, event) do
    Phoenix.PubSub.broadcast(
      Assetronics.PubSub,
      "departments:#{tenant}",
      {event, department}
    )

    result
  end

  defp broadcast_result(result, _tenant, _event), do: result
end
