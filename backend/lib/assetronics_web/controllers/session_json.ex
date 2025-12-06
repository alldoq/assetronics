defmodule AssetronicsWeb.SessionJSON do
  @moduledoc """
  Renders session-related responses (login, logout, refresh, etc.).
  """

  alias Assetronics.Accounts.User

  @doc """
  Renders login response with tokens and user data.
  """
  def login(%{user: user, access_token: access_token, refresh_token: refresh_token}) do
    %{
      data: %{
        access_token: access_token,
        refresh_token: refresh_token,
        token_type: "Bearer",
        expires_in: 3600,
        user: user_data(user)
      }
    }
  end

  @doc """
  Renders logout response.
  """
  def logout(%{message: message}) do
    %{
      data: %{
        message: message
      }
    }
  end

  @doc """
  Renders refresh token response.
  """
  def refresh(%{access_token: access_token}) do
    %{
      data: %{
        access_token: access_token,
        token_type: "Bearer",
        expires_in: 3600
      }
    }
  end

  @doc """
  Renders current user response.
  """
  def me(%{user: user, tenant: tenant}) do
    %{
      data: %{
        user: user_data(user),
        tenant: tenant
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
      inserted_at: user.inserted_at,
      updated_at: user.updated_at
    }
  end
end
