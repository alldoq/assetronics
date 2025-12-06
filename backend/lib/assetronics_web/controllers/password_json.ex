defmodule AssetronicsWeb.PasswordJSON do
  @moduledoc """
  Renders password-related responses.
  """

  @doc """
  Renders password reset request response.
  """
  def reset_requested(%{message: message}) do
    %{
      data: %{
        message: message
      }
    }
  end

  @doc """
  Renders password reset confirmation response.
  """
  def reset_confirmed(%{message: message}) do
    %{
      data: %{
        message: message
      }
    }
  end

  @doc """
  Renders password change response.
  """
  def password_changed(%{message: message}) do
    %{
      data: %{
        message: message
      }
    }
  end

  @doc """
  Renders email verification response.
  """
  def email_verified(%{message: message}) do
    %{
      data: %{
        message: message
      }
    }
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

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
