defmodule AssetronicsWeb.OrganizationJSON do
  @moduledoc """
  Renders organization-related responses.
  """

  alias Assetronics.Organizations.Organization

  @doc """
  Renders a list of organizations.
  """
  def index(%{organizations: organizations}) do
    %{data: for(organization <- organizations, do: data(organization))}
  end

  @doc """
  Renders a single organization.
  """
  def show(%{organization: organization}) do
    %{data: data(organization)}
  end

  defp data(%Organization{} = organization) do
    %{
      id: organization.id,
      name: organization.name,
      type: organization.type,
      description: organization.description,
      parent_id: organization.parent_id,
      parent: parent_data(organization.parent),
      children: children_data(organization.children),
      created_at: organization.inserted_at,
      updated_at: organization.updated_at
    }
  end

  defp parent_data(%Ecto.Association.NotLoaded{}), do: nil
  defp parent_data(nil), do: nil

  defp parent_data(%Organization{} = parent) do
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
