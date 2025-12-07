defmodule Assetronics.Integrations.Adapters.BambooHR.Client do
  @moduledoc """
  Handles authentication and client building for BambooHR API.

  Manages OAuth and API key authentication, constructs Tesla clients,
  and extracts subdomain configuration.
  """

  require Logger

  @doc """
  Builds a Tesla client configured for BambooHR API requests.

  Determines authentication method (API Key > OAuth) and configures
  the client with appropriate headers and middleware.
  """
  def build_client(%{id: id, auth_type: auth_type} = integration) do
    subdomain = get_subdomain(integration)
    base_url = "https://#{subdomain}.bamboohr.com/api/v1"

    Logger.info("Building BambooHR client - Integration ID: #{id}")
    Logger.info("Auth type: #{auth_type}")

    auth_header = build_auth_header(integration)

    Logger.info("BambooHR API base URL: #{base_url}")

    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Headers, [
        {"accept", "application/json"},
        auth_header
      ]},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Timeout, timeout: 30_000}
    ]

    Tesla.client(middleware)
  end

  @doc """
  Extracts the BambooHR subdomain from integration configuration.

  Looks for subdomain in auth_config or parses it from base_url.
  """
  def get_subdomain(integration) do
    cond do
      integration.auth_config && integration.auth_config["subdomain"] ->
        integration.auth_config["subdomain"]

      integration.base_url ->
        # Extract subdomain from URL like https://trial1bcb4c20.bamboohr.com/
        integration.base_url
        |> String.replace("https://", "")
        |> String.replace("http://", "")
        |> String.split(".")
        |> List.first()

      true ->
        Logger.error("No subdomain found for BambooHR integration #{integration.id}")
        "unknown"
    end
  end

  # Private functions

  defp build_auth_header(%{id: id} = integration) do
    # Priority: API Key > OAuth Access Token
    # BambooHR OAuth may be for identity only, while API keys provide full API access
    cond do
      # Prefer API key if available (more reliable for API access)
      integration.api_key && integration.api_key != "" ->
        Logger.info("Using API key authentication for BambooHR integration #{id}")
        Logger.debug("API key (first 10 chars): #{String.slice(integration.api_key, 0, 10)}...")
        # BambooHR API key format: API_KEY:x (key as username, 'x' as password)
        {"authorization", "Basic #{Base.encode64("#{integration.api_key}:x")}"}

      # Fall back to OAuth access token
      integration.access_token && integration.access_token != "" ->
        Logger.info("Using OAuth access token for BambooHR integration #{id}")
        Logger.debug("Access token (first 10 chars): #{String.slice(integration.access_token, 0, 10)}...")
        Logger.warning("Note: BambooHR OAuth may not grant API data access. Consider using API key instead.")
        {"authorization", "Bearer #{integration.access_token}"}

      # No valid credentials
      true ->
        Logger.error("No valid credentials found for BambooHR integration #{id}")
        Logger.error("Please provide either an API key (recommended) or complete OAuth flow")
        {"authorization", "Invalid"}
    end
  end
end