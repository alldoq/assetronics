defmodule Assetronics.Integrations.Adapters.Okta.Client do
  @moduledoc """
  Handles authentication and client building for Okta API.

  Manages API token (SSWS) and OAuth 2.0 authentication, constructs Tesla clients,
  and handles Okta domain configuration.
  """

  require Logger

  @doc """
  Builds a Tesla client configured for Okta API requests.

  Determines authentication method (OAuth 2.0 > API Token) and configures
  the client with appropriate headers and middleware.
  """
  def build_client(%{id: id, auth_type: auth_type} = integration) do
    base_url = get_base_url(integration)

    Logger.info("Building Okta client - Integration ID: #{id}")
    Logger.info("Auth type: #{auth_type}")

    auth_header = build_auth_header(integration)

    Logger.info("Okta API base URL: #{base_url}")

    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Headers, [
        {"accept", "application/json"},
        {"content-type", "application/json"},
        auth_header
      ]},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Timeout, timeout: 30_000},
      {Tesla.Middleware.FollowRedirects, max_redirects: 3}
    ]

    Tesla.client(middleware)
  end

  @doc """
  Extracts the Okta base URL from integration configuration.

  Looks for domain in auth_config or uses base_url directly.
  Format: https://{your-domain}.okta.com/api/v1
  """
  def get_base_url(integration) do
    cond do
      integration.base_url && String.contains?(integration.base_url, "/api/v1") ->
        integration.base_url

      integration.base_url ->
        String.trim_trailing(integration.base_url, "/") <> "/api/v1"

      integration.auth_config && integration.auth_config["domain"] ->
        domain = integration.auth_config["domain"]
        # Handle both full URLs and just domain names
        if String.starts_with?(domain, "http") do
          String.trim_trailing(domain, "/") <> "/api/v1"
        else
          "https://#{domain}/api/v1"
        end

      true ->
        Logger.error("No domain or base_url found for Okta integration #{integration.id}")
        "https://unknown.okta.com/api/v1"
    end
  end

  # Private functions

  defp build_auth_header(%{id: id} = integration) do
    # Priority: OAuth 2.0 Access Token > API Token (SSWS)
    # OAuth 2.0 is recommended by Okta for fine-grained access control
    cond do
      # Prefer OAuth 2.0 if available
      integration.access_token && integration.access_token != "" ->
        Logger.info("Using OAuth 2.0 Bearer token for Okta integration #{id}")
        Logger.debug("Access token (first 10 chars): #{String.slice(integration.access_token, 0, 10)}...")
        {"authorization", "Bearer #{integration.access_token}"}

      # Fall back to API Token with SSWS scheme
      integration.api_key && integration.api_key != "" ->
        Logger.info("Using SSWS API token for Okta integration #{id}")
        Logger.debug("API token (first 10 chars): #{String.slice(integration.api_key, 0, 10)}...")
        # Okta uses SSWS (Simple Shared Web Service) authentication scheme for API tokens
        {"authorization", "SSWS #{integration.api_key}"}

      # No valid credentials
      true ->
        Logger.error("No valid credentials found for Okta integration #{id}")
        Logger.error("Please provide either an OAuth 2.0 access token (recommended) or API token")
        {"authorization", "Invalid"}
    end
  end
end