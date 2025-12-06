defmodule AssetronicsWeb.UserJSON do
  @moduledoc """
  Renders user-related responses.
  """

  alias Assetronics.Accounts.User

  @doc """
  Renders a list of users.
  """
  def index(%{users: users}) do
    %{data: for(user <- users, do: user_data(user))}
  end

  @doc """
  Renders a single user.
  """
  def show(%{user: user}) do
    %{data: user_data(user)}
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

  defp user_data(%User{} = user) do
    %{
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      role: user.role,
      status: user.status,
      phone: user.phone,
      avatar_url: user.avatar_url,
      timezone: user.timezone,
      locale: user.locale,
      email_verified: !is_nil(user.email_verified_at),
      last_login_at: user.last_login_at,
      locked: !is_nil(user.locked_at),
      inserted_at: user.inserted_at,
      updated_at: user.updated_at
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
