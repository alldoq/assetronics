defmodule AssetronicsWeb.SessionController do
  @moduledoc """
  Handles user authentication sessions.

  Endpoints:
  - POST /api/auth/login - Authenticate user and return tokens
  - POST /api/auth/logout - Revoke current token
  - POST /api/auth/refresh - Refresh access token using refresh token
  - GET /api/auth/me - Get current user information
  """

  use AssetronicsWeb, :controller

  alias Assetronics.Accounts
  alias Assetronics.Guardian
  alias AssetronicsWeb.Plugs.AuthPlug

  action_fallback AssetronicsWeb.FallbackController

  @doc """
  Authenticates a user and returns JWT tokens.

  ## Parameters
  - email: User's email address
  - password: User's password
  - tenant: Tenant slug (from subdomain or header)

  ## Response
  - 200: Returns access_token, refresh_token, and user data
  - 401: Invalid credentials
  - 403: Account locked or inactive
  """
  def login(conn, %{"email" => email, "password" => password}) do
    tenant = get_tenant(conn)

    case Accounts.authenticate_user(tenant, email, password) do
      {:ok, user} ->
        # Record successful login
        ip_address = get_client_ip(conn)
        {:ok, user} = Accounts.record_login(tenant, user, ip_address)

        # Generate tokens
        case Guardian.generate_tokens(user, tenant) do
          {:ok, tokens} ->
            conn
            |> put_status(:ok)
            |> render(:login, %{
              user: user,
              access_token: tokens.access_token,
              refresh_token: tokens.refresh_token
            })

          {:error, reason} ->
            conn
            |> put_status(:internal_server_error)
            |> render(:error, message: "Failed to generate tokens: #{inspect(reason)}")
        end

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> render(:error, message: "Invalid email or password")

      {:error, :account_locked} ->
        conn
        |> put_status(:forbidden)
        |> render(:error, message: "Account is locked due to too many failed login attempts")

      {:error, :account_inactive} ->
        conn
        |> put_status(:forbidden)
        |> render(:error, message: "Account is inactive")

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> render(:error, message: "Authentication failed: #{inspect(reason)}")
    end
  end

  @doc """
  Logs out the current user by revoking their token.

  ## Response
  - 200: Successfully logged out
  - 401: Not authenticated
  """
  def logout(conn, _params) do
    # Extract token
    case AuthPlug.extract_token(conn) do
      {:ok, token} ->
        # Revoke the token
        Guardian.revoke_token(token)

        conn
        |> put_status(:ok)
        |> render(:logout, message: "Successfully logged out")

      {:error, :no_token} ->
        conn
        |> put_status(:unauthorized)
        |> render(:error, message: "No token provided")
    end
  end

  @doc """
  Refreshes an access token using a refresh token.

  ## Parameters
  - refresh_token: The refresh token

  ## Response
  - 200: Returns new access_token
  - 401: Invalid or expired refresh token
  """
  def refresh(conn, %{"refresh_token" => refresh_token}) do
    case Guardian.refresh_access_token(refresh_token) do
      {:ok, access_token, _claims} ->
        conn
        |> put_status(:ok)
        |> render(:refresh, access_token: access_token)

      {:error, :invalid_token_type} ->
        conn
        |> put_status(:unauthorized)
        |> render(:error, message: "Token is not a refresh token")

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> render(:error, message: "Invalid refresh token: #{inspect(reason)}")
    end
  end

  @doc """
  Returns the current authenticated user's information.

  ## Response
  - 200: Returns user data
  - 401: Not authenticated
  """
  def me(conn, _params) do
    user = conn.assigns[:current_user]
    tenant = conn.assigns[:tenant]

    conn
    |> put_status(:ok)
    |> render(:me, user: user, tenant: tenant)
  end

  # Private functions

  defp get_tenant(conn) do
    # Check if tenant is in assigns (from TenantResolver plug)
    case conn.assigns[:tenant] do
      nil ->
        # Fallback to tenant header (try both variations)
        case get_req_header(conn, "x-tenant-id") do
          [tenant] -> tenant
          _ ->
            case get_req_header(conn, "x-tenant") do
              [tenant] -> tenant
              _ -> raise "Tenant not found in request"
            end
        end

      tenant ->
        tenant
    end
  end

  defp get_client_ip(conn) do
    # Check for X-Forwarded-For header (proxy/load balancer)
    case get_req_header(conn, "x-forwarded-for") do
      [ip | _] ->
        ip
        |> String.split(",")
        |> List.first()
        |> String.trim()

      _ ->
        # Fallback to remote_ip
        conn.remote_ip
        |> :inet.ntoa()
        |> to_string()
    end
  end
end
