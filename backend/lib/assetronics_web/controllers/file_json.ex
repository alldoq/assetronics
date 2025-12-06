defmodule AssetronicsWeb.FileJSON do
  @moduledoc """
  Renders file-related responses.
  """

  alias Assetronics.Files.File

  @doc """
  Renders a list of files.
  """
  def index(%{files: files}) do
    %{data: for(file <- files, do: file_data(file))}
  end

  @doc """
  Renders a single file.
  """
  def show(%{file: file}) do
    %{data: file_data(file)}
  end

  @doc """
  Renders error response.
  """
  def error(%{message: message}) do
    %{
      error: %{
        message: message
      }
    }
  end

  def error(%{changeset: changeset}) do
    %{
      error: %{
        message: "Validation failed",
        details: translate_errors(changeset)
      }
    }
  end

  # Private functions

  defp file_data(%File{} = file) do
    %{
      id: file.id,
      filename: file.filename,
      original_filename: file.original_filename,
      content_type: file.content_type,
      file_size: file.file_size,
      category: file.category,
      storage_provider: file.storage_provider,
      url: Map.get(file, :url),
      width: file.width,
      height: file.height,
      uploaded_by_id: file.uploaded_by_id,
      asset_id: file.asset_id,
      # TODO: Uncomment when WorkflowExecution schema is created
      # workflow_execution_id: file.workflow_execution_id,
      attachable_type: file.attachable_type,
      attachable_id: file.attachable_id,
      inserted_at: file.inserted_at,
      updated_at: file.updated_at
    }
  end

  defp file_data(file) when is_map(file) do
    %{
      id: Map.get(file, :id),
      filename: Map.get(file, :filename),
      original_filename: Map.get(file, :original_filename),
      content_type: Map.get(file, :content_type),
      file_size: Map.get(file, :file_size),
      category: Map.get(file, :category),
      storage_provider: Map.get(file, :storage_provider),
      url: Map.get(file, :url),
      width: Map.get(file, :width),
      height: Map.get(file, :height),
      uploaded_by_id: Map.get(file, :uploaded_by_id),
      asset_id: Map.get(file, :asset_id),
      workflow_execution_id: Map.get(file, :workflow_execution_id),
      attachable_type: Map.get(file, :attachable_type),
      attachable_id: Map.get(file, :attachable_id),
      inserted_at: Map.get(file, :inserted_at),
      updated_at: Map.get(file, :updated_at)
    }
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
