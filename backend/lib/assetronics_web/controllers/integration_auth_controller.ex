defmodule AssetronicsWeb.IntegrationAuthController do
  use AssetronicsWeb, :controller
  require Logger
  alias Assetronics.Integrations

  # Initiates the OAuth flow
  def connect(conn, %{"provider" => provider, "integration_id" => id}) do
    tenant = conn.assigns[:tenant] || get_req_header(conn, "x-tenant-id") |> List.first()

    # Get the integration to retrieve tenant-specific OAuth credentials
    case Integrations.get_integration!(tenant, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Integration not found"})

      integration ->
        # Generate state to prevent CSRF and pass context
        state = encode_state(id, tenant, provider)

        case build_auth_url(provider, state, integration) do
          {:ok, auth_url} ->
            Logger.info("Initiating OAuth flow for #{provider}, integration: #{id}")
            json(conn, %{url: auth_url})

          {:error, reason} ->
            Logger.error("Failed to build OAuth URL for #{provider}: #{reason}")
            conn
            |> put_status(:bad_request)
            |> json(%{error: reason})
        end
    end
  end

  defp build_auth_url("dell", state, integration) do
    # Dell Premier OAuth URL - read credentials from integration.auth_config
    client_id = get_in(integration.auth_config, ["client_id"])
    redirect_uri = get_redirect_uri()

    if is_nil(client_id) do
      {:error, "Dell OAuth client_id not configured for this integration. Please provide your Dell Premier OAuth credentials."}
    else
      query = URI.encode_query(%{
        response_type: "code",
        client_id: client_id,
        redirect_uri: redirect_uri,
        scope: "purchasing",
        state: state
      })

      {:ok, "https://apigtwb2c.us.dell.com/auth/oauth/v2/authorize?#{query}"}
    end
  end

  defp build_auth_url("intune", state, integration) do
    # Microsoft Identity Platform - read credentials from integration.auth_config
    client_id = get_in(integration.auth_config, ["client_id"])
    redirect_uri = get_redirect_uri()

    if is_nil(client_id) do
      {:error, "Microsoft OAuth client_id not configured for this integration. Please provide your Azure AD app credentials."}
    else
      query = URI.encode_query(%{
        response_type: "code",
        client_id: client_id,
        redirect_uri: redirect_uri,
        scope: "DeviceManagementManagedDevices.Read.All User.Read.All offline_access",
        state: state,
        response_mode: "query"
      })

      {:ok, "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?#{query}"}
    end
  end

  defp build_auth_url("bamboohr", state, integration) do
    # BambooHR OAuth - read credentials from integration.auth_config
    client_id = get_in(integration.auth_config, ["client_id"])
    redirect_uri = get_redirect_uri()
    base_url = integration.base_url

    cond do
      is_nil(client_id) ->
        {:error, "BambooHR OAuth client_id not configured for this integration. Please provide your BambooHR API credentials."}

      is_nil(base_url) ->
        {:error, "BambooHR instance URL not configured. Please provide your BambooHR domain (e.g., https://your-company.bamboohr.com)"}

      true ->
        # Extract subdomain from base_url if full URL provided
        subdomain = extract_bamboohr_subdomain(base_url)
        Logger.info("BambooHR base_url: #{base_url}, extracted subdomain: #{subdomain}")

        # BambooHR OAuth parameters - request=authorize is REQUIRED
        # Per BambooHR docs: https://documentation.bamboohr.com/docs/getting-started
        # Required scopes: openid+email (literal plus sign, not URL-encoded)
        # We build the query manually to avoid encoding the plus sign
        base_params = %{
          request: "authorize",
          response_type: "code",
          client_id: client_id,
          redirect_uri: redirect_uri,
          state: state
        }

        # Encode params but build query manually to preserve the literal + in scope
        encoded_params = Enum.map_join(base_params, "&", fn {key, value} ->
          "#{URI.encode(to_string(key), &URI.char_unreserved?/1)}=#{URI.encode(to_string(value), &URI.char_unreserved?/1)}"
        end)

        query = encoded_params <> "&scope=offline_access+openid+email+employee"

        auth_url = "https://#{subdomain}.bamboohr.com/authorize.php?#{query}"
        Logger.info("BambooHR Auth URL: #{auth_url}")

        {:ok, auth_url}
    end
  end

  # Catch-all for unsupported providers
  defp build_auth_url(provider, _state, _integration) do
    {:error, "OAuth not supported for provider: #{provider}"}
  end

  defp extract_bamboohr_subdomain(base_url) do
    base_url
    |> String.replace("https://", "")
    |> String.replace("http://", "")
    |> String.split(".")
    |> List.first()
  end


  defp get_redirect_uri do
    Application.get_env(:assetronics, :oauth_redirect_uri, "http://localhost:4000/api/v1/oauth/callback")
  end

  defp encode_state(id, tenant, provider) do
    # Using Phoenix.Token for secure state encoding with expiration
    # This prevents CSRF attacks and tampering
    Phoenix.Token.sign(
      AssetronicsWeb.Endpoint,
      "oauth_state",
      %{integration_id: id, tenant: tenant, provider: provider},
      max_age: 600  # 10 minutes to complete OAuth flow
    )
  end
end
