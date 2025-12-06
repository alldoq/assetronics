defmodule AssetronicsWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use AssetronicsWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: AssetronicsWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: AssetronicsWeb.ErrorJSON)
    |> render(:"404")
  end

  # Handle custom errors
  def call(conn, {:error, :invalid_id}) do
    conn
    |> put_status(:bad_request)
    |> put_view(json: AssetronicsWeb.ErrorJSON)
    |> render(:error, message: "Invalid ID format - expected UUID")
  end

  def call(conn, {:error, :employee_required}) do
    conn
    |> put_status(:bad_request)
    |> put_view(json: AssetronicsWeb.ErrorJSON)
    |> render(:error, message: "Employee ID is required")
  end

  def call(conn, {:error, :last_step}) do
    conn
    |> put_status(:bad_request)
    |> put_view(json: AssetronicsWeb.ErrorJSON)
    |> render(:error, message: "Already at last step")
  end

  def call(conn, {:error, :unsupported_integration}) do
    conn
    |> put_status(:bad_request)
    |> put_view(json: AssetronicsWeb.ErrorJSON)
    |> render(:error, message: "Unsupported integration type")
  end

  # Generic error handler
  def call(conn, {:error, reason}) when is_atom(reason) do
    conn
    |> put_status(:bad_request)
    |> put_view(json: AssetronicsWeb.ErrorJSON)
    |> render(:error, message: to_string(reason))
  end

  def call(conn, {:error, reason}) when is_binary(reason) do
    conn
    |> put_status(:bad_request)
    |> put_view(json: AssetronicsWeb.ErrorJSON)
    |> render(:error, message: reason)
  end
end
