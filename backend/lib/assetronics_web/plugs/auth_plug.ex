defmodule AssetronicsWeb.Plugs.AuthPlug do
  @moduledoc """
  Authentication plug for API endpoints.

  Extracts and verifies JWT tokens from the Authorization header.
  Loads the authenticated user and tenant into conn.assigns.

  ## Usage

      pipeline :authenticated do
        plug AssetronicsWeb.Plugs.AuthPlug
      end

  ## Assigns

  - `current_user` - The authenticated user
  - `tenant` - The tenant slug from the JWT claims
  """

  import Plug.Conn
  import Phoenix.Controller

  alias Assetronics.Guardian

  def init(opts), do: opts

  def call(conn, _opts) do
    require Logger

    with {:ok, token} <- extract_token(conn),
         {:ok, claims} <- Guardian.decode_and_verify(token),
         {:ok, {user, tenant}} <- Guardian.resource_from_claims(claims) do
      conn
      |> assign(:current_user, user)
      |> assign(:tenant, tenant)
      |> assign(:claims, claims)
    else
      {:error, :no_token} ->
        Logger.warning("Auth failed: No token provided")
        conn
        |> put_status(:unauthorized)
        |> put_view(json: AssetronicsWeb.ErrorJSON)
        |> render(:"401", message: "Missing authorization token")
        |> halt()

      {:error, :invalid_token} ->
        Logger.warning("Auth failed: Invalid token")
        conn
        |> put_status(:unauthorized)
        |> put_view(json: AssetronicsWeb.ErrorJSON)
        |> render(:"401", message: "Invalid authorization token")
        |> halt()

      {:error, :user_not_found} ->
        Logger.warning("Auth failed: User not found")
        conn
        |> put_status(:unauthorized)
        |> put_view(json: AssetronicsWeb.ErrorJSON)
        |> render(:"401", message: "User not found")
        |> halt()

      {:error, :token_expired} ->
        Logger.warning("Auth failed: Token expired")
        conn
        |> put_status(:unauthorized)
        |> put_view(json: AssetronicsWeb.ErrorJSON)
        |> render(:"401", message: "Token expired")
        |> halt()

      {:error, reason} ->
        Logger.error("Auth failed with reason: #{inspect(reason)}")
        conn
        |> put_status(:unauthorized)
        |> put_view(json: AssetronicsWeb.ErrorJSON)
        |> render(:"401", message: "Authentication failed")
        |> halt()
    end
  end

  @doc """
  Extracts the Bearer token from the Authorization header.
  """
  def extract_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, token}
      _ -> {:error, :no_token}
    end
  end

  @doc """
  Returns the current user from conn.assigns.
  """
  def current_user(conn) do
    conn.assigns[:current_user]
  end

  @doc """
  Returns the current tenant from conn.assigns.
  """
  def current_tenant(conn) do
    conn.assigns[:tenant]
  end

  @doc """
  Checks if the current user has the specified role.
  """
  def has_role?(conn, role) do
    user = current_user(conn)
    user && user.role == to_string(role)
  end

  @doc """
  Checks if the current user has any of the specified roles.
  """
  def has_any_role?(conn, roles) do
    user = current_user(conn)
    user && Enum.any?(roles, fn role -> user.role == to_string(role) end)
  end
end
