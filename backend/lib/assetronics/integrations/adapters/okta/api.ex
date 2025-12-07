defmodule Assetronics.Integrations.Adapters.Okta.Api do
  @moduledoc """
  Handles API communication with Okta endpoints.

  Provides functions for fetching users, testing connections,
  and managing HTTP requests with pagination support.
  """

  require Logger

  @doc """
  Tests the connection to Okta API.

  Uses the /users endpoint with a limit of 1 for quick connectivity check.
  """
  def test_connection(client) do
    Logger.info("Testing Okta connection with /users endpoint")

    case Tesla.get(client, "/users?limit=1") do
      {:ok, %Tesla.Env{status: 200}} ->
        Logger.info("Successfully connected to Okta")
        {:ok, %{status: "connected", message: "Successfully connected to Okta"}}

      {:ok, %Tesla.Env{status: 401, body: body}} ->
        Logger.error("Okta connection unauthorized: #{inspect(body)}")
        {:error, :unauthorized}

      {:ok, %Tesla.Env{status: 403, body: body}} ->
        Logger.error("Okta connection forbidden: #{inspect(body)}")
        {:error, :forbidden}

      {:ok, %Tesla.Env{status: 404, body: body}} ->
        Logger.error("Okta endpoint not found (check domain): #{inspect(body)}")
        {:error, :not_found}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error("Okta connection failed with status #{status}: #{inspect(body)}")
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        Logger.error("Okta connection error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetches all users from Okta with pagination support.

  Okta limits responses to 200 users per page. This function handles
  pagination automatically using the Link header.
  """
  def fetch_users(client) do
    Logger.info("Fetching Okta users...")

    # Start with the first page - fetch all active and deprovisioned users
    # filter=status eq "ACTIVE" or status eq "DEPROVISIONED" or status eq "SUSPENDED"
    initial_url = "/users?limit=200"

    case fetch_users_recursive(client, initial_url, []) do
      {:ok, users} ->
        Logger.info("Fetched #{length(users)} total users from Okta")
        {:ok, users}

      error ->
        error
    end
  end

  @doc """
  Fetches a single user by ID from Okta.
  """
  def fetch_user(client, user_id) do
    Logger.info("Fetching Okta user: #{user_id}")

    case Tesla.get(client, "/users/#{user_id}") do
      {:ok, %Tesla.Env{status: 200, body: user}} when is_map(user) ->
        {:ok, user}

      {:ok, %Tesla.Env{status: 404, body: body}} ->
        Logger.warning("Okta user not found: #{user_id} - #{inspect(body)}")
        {:error, :not_found}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error("Failed to fetch Okta user #{user_id}: #{status} - #{inspect(body)}")
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        Logger.error("Failed to fetch Okta user #{user_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private functions

  defp fetch_users_recursive(client, url, accumulated_users) do
    case Tesla.get(client, url) do
      {:ok, %Tesla.Env{status: 200, body: users, headers: headers}} when is_list(users) ->
        new_accumulated = accumulated_users ++ users

        # Check for pagination via Link header
        case get_next_page_url(headers) do
          nil ->
            # No more pages
            {:ok, new_accumulated}

          next_url ->
            # Fetch next page
            Logger.debug("Fetching next page of Okta users (#{length(new_accumulated)} so far)...")
            fetch_users_recursive(client, next_url, new_accumulated)
        end

      {:ok, %Tesla.Env{status: 200, body: body}} when is_map(body) ->
        # Unexpected single user response
        Logger.warning("Unexpected single user response from Okta: #{inspect(body)}")
        {:ok, accumulated_users ++ [body]}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error("Okta fetch users failed: #{status} - #{inspect(body)}")
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        Logger.error("Failed to fetch users from Okta: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp get_next_page_url(headers) do
    # Okta uses Link header for pagination
    # Example: <https://your-domain.okta.com/api/v1/users?after=cursor>; rel="next"
    link_header = Enum.find_value(headers, fn
      {"link", value} -> value
      _ -> nil
    end)

    if link_header do
      # Parse Link header to extract next URL
      case Regex.run(~r/<([^>]+)>;\s*rel="next"/, link_header) do
        [_, url] ->
          # Extract just the path and query from the full URL
          uri = URI.parse(url)
          "#{uri.path}?#{uri.query}"

        _ ->
          nil
      end
    else
      nil
    end
  end
end