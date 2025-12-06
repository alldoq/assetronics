defmodule Assetronics.Guardian do
  @moduledoc """
  Guardian implementation for JWT-based authentication.

  Handles token generation, verification, and user lookup.
  """

  use Guardian, otp_app: :assetronics

  alias Assetronics.Accounts
  alias Assetronics.Accounts.User

  @doc """
  Fetches the JWT secret key from environment variables.

  Falls back to a default key in development (NOT FOR PRODUCTION).
  """
  def fetch_secret_key do
    case System.get_env("GUARDIAN_SECRET_KEY") do
      nil ->
        # Generate a secret in development mode
        if Mix.env() == :prod do
          raise "GUARDIAN_SECRET_KEY environment variable must be set in production"
        else
          # Default key for development (generate with: mix phx.gen.secret)
          "development_secret_key_change_this_in_production_min_32_chars_long"
        end

      key ->
        key
    end
  end

  @doc """
  Encodes the user information into the JWT token.

  The subject (sub) is the user ID, and we include the tenant slug
  in the claims for multi-tenancy support.
  """
  def subject_for_token(%User{} = user, %{"tenant" => tenant}) do
    {:ok, "User:#{tenant}:#{user.id}"}
  end

  def subject_for_token(_, _) do
    {:error, :invalid_subject}
  end

  @doc """
  Decodes the JWT token and retrieves the user from the database.
  """
  def resource_from_claims(%{"sub" => "User:" <> rest}) do
    case String.split(rest, ":", parts: 2) do
      [tenant, user_id] ->
        # Validate UUID format before querying
        case Ecto.UUID.cast(user_id) do
          {:ok, _uuid} ->
            user = Accounts.get_user!(tenant, user_id)
            {:ok, {user, tenant}}

          :error ->
            {:error, :invalid_user_id}
        end

      _ ->
        {:error, :invalid_subject}
    end
  rescue
    Ecto.NoResultsError -> {:error, :user_not_found}
  end

  def resource_from_claims(_claims) do
    {:error, :invalid_claims}
  end

  @doc """
  Builds claims for the JWT token.

  Includes:
  - User ID and email
  - Tenant slug
  - User role
  - Token type (access or refresh)
  """
  def build_claims(claims, %User{} = user, %{"tenant" => tenant} = opts) do
    claims =
      claims
      |> Map.put("user_id", user.id)
      |> Map.put("email", user.email)
      |> Map.put("role", user.role)
      |> Map.put("tenant", tenant)

    # Add token type if specified
    claims = case opts do
      %{"token_type" => token_type} -> Map.put(claims, "typ", token_type)
      _ -> claims
    end

    {:ok, claims}
  end

  def build_claims(claims, _resource, _opts) do
    {:ok, claims}
  end

  @doc """
  Generates an access token for a user.

  Access tokens are short-lived (1 hour by default).
  """
  def generate_access_token(user, tenant) do
    encode_and_sign(
      user,
      %{"tenant" => tenant, "token_type" => "access"},
      ttl: {1, :hour}
    )
  end

  @doc """
  Generates a refresh token for a user.

  Refresh tokens are long-lived (30 days by default).
  """
  def generate_refresh_token(user, tenant) do
    encode_and_sign(
      user,
      %{"tenant" => tenant, "token_type" => "refresh"},
      ttl: {30, :days}
    )
  end

  @doc """
  Generates both access and refresh tokens.

  Returns a tuple with {access_token, refresh_token}.
  """
  def generate_tokens(user, tenant) do
    with {:ok, access_token, _claims} <- generate_access_token(user, tenant),
         {:ok, refresh_token, _claims} <- generate_refresh_token(user, tenant) do
      {:ok, %{access_token: access_token, refresh_token: refresh_token}}
    end
  end

  @doc """
  Verifies and refreshes an access token using a refresh token.
  """
  def refresh_access_token(refresh_token) do
    with {:ok, claims} <- decode_and_verify(refresh_token),
         {:ok, {user, tenant}} <- resource_from_claims(claims) do
      # Verify it's a refresh token
      case claims["typ"] do
        "refresh" ->
          generate_access_token(user, tenant)

        _ ->
          {:error, :invalid_token_type}
      end
    end
  end

  @doc """
  Revokes a token (adds it to a blacklist).

  Note: This requires additional infrastructure (Redis, database table, etc.)
  for production use. This is a placeholder implementation.
  """
  def revoke_token(token) do
    # TODO: Implement token blacklisting
    # Options:
    # 1. Store revoked tokens in Redis with TTL matching token expiry
    # 2. Store in database table with cleanup job
    # 3. Use Guardian.DB for token tracking
    {:ok, token}
  end

  @doc """
  Verifies if a token is valid and not revoked.
  """
  def verify_token(token) do
    # TODO: Check against blacklist
    decode_and_verify(token)
  end
end
