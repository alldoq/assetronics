defmodule AssetronicsWeb.DepartmentJSON do
  @moduledoc """
  Renders department-related responses.
  """

  alias Assetronics.Departments.Department

  @doc """
  Renders a list of departments.
  """
  def index(%{departments: departments}) do
    %{data: for(department <- departments, do: data(department))}
  end

  @doc """
  Renders a single department.
  """
  def show(%{department: department}) do
    %{data: data(department)}
  end

  defp data(%Department{} = department) do
    %{
      id: department.id,
      name: department.name,
      type: department.type,
      description: department.description,
      code: department.code,
      parent_id: department.parent_id,
      parent: parent_data(department.parent),
      children: children_data(department.children),
      created_at: department.inserted_at,
      updated_at: department.updated_at
    }
  end

  defp parent_data(%Ecto.Association.NotLoaded{}), do: nil
  defp parent_data(nil), do: nil

  defp parent_data(%Department{} = parent) do
    %{
      id: parent.id,
      name: parent.name,
      type: parent.type
    }
  end

  defp children_data(%Ecto.Association.NotLoaded{}), do: nil
  defp children_data(nil), do: nil
  defp children_data([]), do: []

  defp children_data(children) when is_list(children) do
    for child <- children do
      %{
        id: child.id,
        name: child.name,
        type: child.type
      }
    end
  end
end
