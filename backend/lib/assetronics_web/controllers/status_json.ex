defmodule AssetronicsWeb.StatusJSON do
  @moduledoc """
  Renders status-related responses.
  """

  alias Assetronics.Statuses.Status

  @doc """
  Renders a list of statuses.
  """
  def index(%{statuses: statuses}) do
    %{data: for(status <- statuses, do: data(status))}
  end

  @doc """
  Renders a single status.
  """
  def show(%{status: status}) do
    %{data: data(status)}
  end

  defp data(%Status{} = status) do
    %{
      id: status.id,
      name: status.name,
      value: status.value,
      description: status.description,
      color: status.color,
      created_at: status.inserted_at,
      updated_at: status.updated_at
    }
  end
end
