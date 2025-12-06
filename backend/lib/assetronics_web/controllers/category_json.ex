defmodule AssetronicsWeb.CategoryJSON do
  @moduledoc """
  Renders category-related responses.
  """

  alias Assetronics.Categories.Category

  @doc """
  Renders a list of categories.
  """
  def index(%{categories: categories}) do
    %{data: for(category <- categories, do: data(category))}
  end

  @doc """
  Renders a single category.
  """
  def show(%{category: category}) do
    %{data: data(category)}
  end

  defp data(%Category{} = category) do
    %{
      id: category.id,
      name: category.name,
      description: category.description,
      created_at: category.inserted_at,
      updated_at: category.updated_at
    }
  end
end
