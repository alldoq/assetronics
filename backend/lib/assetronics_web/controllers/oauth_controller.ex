defmodule AssetronicsWeb.OAuthController do
  use AssetronicsWeb, :controller
  alias Assetronics.Integrations
  require Logger

  # This controller handles the OAuth callback from providers like Intune, Dell, etc.
  # It is responsible for exchanging the authorization code for an access token
  # and updating the integration record.

  # Handle OAuth errors returned by the provider
  def callback(conn, %{"error" => error} = params) do
    error_description = Map.get(params, "error_description", "No description provided")
    _provider = Map.get(params, "provider", "unknown")

    Logger.error("OAuth callback error: #{error} - #{error_description}")

    # Redirect to frontend with error message
    frontend_url = Application.get_env(:assetronics, :frontend_url, "http://localhost:5173")
    redirect(conn, external: "#{frontend_url}/settings/integrations?error=#{error}&message=#{URI.encode(error_description)}")
  end

  def callback(conn, %{"code" => code, "state" => state} = _params) do
    # 1. Decode state to find the integration_id and tenant
    # State should be a signed/encrypted string to prevent CSRF

    case decode_state(state) do
      {:ok, %{integration_id: id, tenant: tenant, provider: provider}} ->
        Logger.info("OAuth callback received for #{provider}, integration: #{id}, tenant: #{tenant}")
        integration = Integrations.get_integration!(tenant, id)

        # 2. Exchange code for token
        Logger.info("Exchanging authorization code for #{provider}...")
        case exchange_code(provider, code, integration) do
          {:ok, token_data} ->
            Logger.info("Successfully exchanged code for #{provider}, updating integration tokens...")
            # 3. Update Integration with tokens
            {:ok, updated_integration} = Integrations.update_tokens(
              tenant,
              integration,
              token_data.access_token,
              token_data.refresh_token,
              token_data.expires_in
            )

            # 4. Activate the integration now that OAuth is complete
            Integrations.update_integration(tenant, updated_integration, %{status: "active"})

            Logger.info("OAuth flow completed successfully for #{provider} integration #{id}")

            # 5. Redirect to frontend settings/integrations page with success message
            frontend_url = Application.get_env(:assetronics, :frontend_url, "http://localhost:5173")
            redirect(conn, external: "#{frontend_url}/settings/integrations?success=true&provider=#{provider}")

          {:error, reason} ->
            Logger.error("Failed to exchange code for #{provider}: #{inspect(reason)}")
            conn
            |> put_status(:bad_request)
            |> json(%{error: "Failed to exchange token: #{inspect(reason)}"})
        end

      {:error, error_reason} ->
        Logger.error("Invalid OAuth state parameter: #{inspect(error_reason)}")
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid state parameter"})
    end
  end

  # Helper functions (Mocked for now)

  defp decode_state(state) do
    # Verify the signed token (prevents CSRF and tampering)
    case Phoenix.Token.verify(
           AssetronicsWeb.Endpoint,
           "oauth_state",
           state,
           max_age: 600  # 10 minutes
         ) do
      {:ok, %{integration_id: id, tenant: tenant, provider: provider}} ->
        {:ok, %{integration_id: id, tenant: tenant, provider: provider}}

      {:error, :expired} ->
        Logger.warning("OAuth state token expired")
        {:error, "OAuth session expired. Please try again."}

      {:error, :invalid} ->
        Logger.warning("Invalid OAuth state token")
        {:error, "Invalid OAuth state. Possible CSRF attempt."}

      {:error, reason} ->
        Logger.error("Failed to verify OAuth state: #{inspect(reason)}")
        {:error, "Invalid state parameter"}
    end
  end

  defp exchange_code("dell", code, integration) do
    # Dell Premier OAuth Token Exchange
    # Documentation: https://apigtwb2c.us.dell.com/auth/oauth/v2/token
    # Credentials are stored per-tenant in integration.auth_config (encrypted)

    client_id = get_in(integration.auth_config, ["client_id"])
    client_secret = get_in(integration.auth_config, ["client_secret"])
    redirect_uri = Application.get_env(:assetronics, :oauth_redirect_uri, "http://localhost:4000/api/v1/oauth/callback")

    if is_nil(client_id) or is_nil(client_secret) do
      {:error, "Dell OAuth credentials not configured for this integration"}
    else
      body = %{
        grant_type: "authorization_code",
        code: code,
        redirect_uri: redirect_uri,
        client_id: client_id,
        client_secret: client_secret
      }

      case Req.post("https://apigtwb2c.us.dell.com/auth/oauth/v2/token",
           form: body,
           headers: [{"content-type", "application/x-www-form-urlencoded"}]) do
        {:ok, %{status: 200, body: response}} ->
          {:ok, %{
            access_token: response["access_token"],
            refresh_token: response["refresh_token"],
            expires_in: response["expires_in"] || 3600
          }}

        {:ok, %{status: status, body: body}} ->
          {:error, "Dell OAuth failed with status #{status}: #{inspect(body)}"}

        {:error, reason} ->
          {:error, "Dell OAuth request failed: #{inspect(reason)}"}
      end
    end
  end

  defp exchange_code("intune", code, integration) do
    # Microsoft Identity Platform Token Exchange
    # Documentation: https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow
    # Credentials are stored per-tenant in integration.auth_config (encrypted)

    client_id = get_in(integration.auth_config, ["client_id"])
    client_secret = get_in(integration.auth_config, ["client_secret"])
    redirect_uri = Application.get_env(:assetronics, :oauth_redirect_uri, "http://localhost:4000/api/v1/oauth/callback")

    if is_nil(client_id) or is_nil(client_secret) do
      {:error, "Microsoft OAuth credentials not configured for this integration"}
    else
      body = %{
        grant_type: "authorization_code",
        code: code,
        redirect_uri: redirect_uri,
        client_id: client_id,
        client_secret: client_secret,
        scope: "DeviceManagementManagedDevices.Read.All User.Read.All offline_access"
      }

      case Req.post("https://login.microsoftonline.com/common/oauth2/v2.0/token",
           form: body,
           headers: [{"content-type", "application/x-www-form-urlencoded"}]) do
        {:ok, %{status: 200, body: response}} ->
          {:ok, %{
            access_token: response["access_token"],
            refresh_token: response["refresh_token"],
            expires_in: response["expires_in"] || 3600
          }}

        {:ok, %{status: status, body: body}} ->
          {:error, "Microsoft OAuth failed with status #{status}: #{inspect(body)}"}

        {:error, reason} ->
          {:error, "Microsoft OAuth request failed: #{inspect(reason)}"}
      end
    end
  end

  defp exchange_code("bamboohr", code, integration) do
    # BambooHR OAuth Token Exchange
    # Documentation: https://documentation.bamboohr.com/docs/getting-started
    # BambooHR requires Basic Authentication in the Authorization header
    # Credentials are stored per-tenant in integration.auth_config (encrypted)

    client_id = get_in(integration.auth_config, ["client_id"])
    client_secret = get_in(integration.auth_config, ["client_secret"])
    redirect_uri = Application.get_env(:assetronics, :oauth_redirect_uri, "http://localhost:4000/api/v1/oauth/callback")
    base_url = integration.base_url

    # Extract subdomain from base_url (handles various URL formats)
    subdomain = extract_bamboohr_subdomain(base_url)

    cond do
      is_nil(client_id) or is_nil(client_secret) ->
        {:error, "BambooHR OAuth credentials not configured for this integration"}

      is_nil(subdomain) ->
        {:error, "BambooHR subdomain not configured"}

      true ->
        # Create Basic Auth header (base64 encoded client_id:client_secret)
        credentials = Base.encode64("#{client_id}:#{client_secret}")

        body = %{
          grant_type: "authorization_code",
          code: code,
          redirect_uri: redirect_uri
        }

        Logger.info("Requesting BambooHR token from: https://#{subdomain}.bamboohr.com/token.php")

        case Req.post("https://#{subdomain}.bamboohr.com/token.php",
             form: body,
             headers: [
               {"authorization", "Basic #{credentials}"},
               {"content-type", "application/x-www-form-urlencoded"}
             ]) do
          {:ok, %{status: 200, body: response_body}} ->
            Logger.info("BambooHR token exchange response - Status: 200, Body: #{inspect(response_body)}")

            access_token = response_body["access_token"]
            refresh_token = response_body["refresh_token"]

            cond do
              is_nil(access_token) or access_token == "" ->
                Logger.error("BambooHR token response missing access_token: #{inspect(response_body)}")
                {:error, "No access_token in BambooHR response"}

              true ->
                {:ok, %{
                  access_token: access_token,
                  refresh_token: refresh_token,
                  expires_in: response_body["expires_in"] || 3600
                }}
            end

          {:ok, %{status: status, body: response_body}} ->
            Logger.error("BambooHR OAuth failed with status #{status}: #{inspect(response_body)}")
            {:error, "BambooHR OAuth failed with status #{status}: #{inspect(response_body)}"}

          {:error, reason} ->
            Logger.error("BambooHR OAuth request failed: #{inspect(reason)}")
            {:error, "BambooHR OAuth request failed: #{inspect(reason)}"}
        end
    end
  end

  defp exchange_code(_, _, _), do: {:error, "Provider not supported"}

  @doc """
  Refreshes an OAuth access token using the refresh token.
  This is called when an access token has expired.

  ## Examples

      iex> refresh_token(tenant, integration)
      {:ok, %{access_token: "new_token", refresh_token: "new_refresh", expires_in: 3600}}

  """
  def refresh_token(tenant, %Assetronics.Integrations.Integration{} = integration) do
    provider = integration.provider

    case do_refresh_token(provider, integration) do
      {:ok, token_data} ->
        # Update integration with new tokens
        case Integrations.update_tokens(
               tenant,
               integration,
               token_data.access_token,
               token_data.refresh_token,
               token_data.expires_in
             ) do
          {:ok, updated_integration} ->
            Logger.info("Successfully refreshed OAuth token for #{provider} integration #{integration.id}")
            {:ok, updated_integration}

          {:error, reason} ->
            Logger.error("Failed to update tokens after refresh: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.error("Failed to refresh token for #{provider}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp do_refresh_token("dell", integration) do
    # Read per-tenant credentials from integration.auth_config (encrypted)
    client_id = get_in(integration.auth_config, ["client_id"])
    client_secret = get_in(integration.auth_config, ["client_secret"])
    refresh_token = get_refresh_token(integration)

    if is_nil(client_id) or is_nil(client_secret) or is_nil(refresh_token) do
      {:error, "Dell OAuth credentials or refresh token not configured for this integration"}
    else
      body = %{
        grant_type: "refresh_token",
        refresh_token: refresh_token,
        client_id: client_id,
        client_secret: client_secret
      }

      case Req.post("https://apigtwb2c.us.dell.com/auth/oauth/v2/token",
           form: body,
           headers: [{"content-type", "application/x-www-form-urlencoded"}]) do
        {:ok, %{status: 200, body: response}} ->
          {:ok, %{
            access_token: response["access_token"],
            refresh_token: response["refresh_token"] || refresh_token,
            expires_in: response["expires_in"] || 3600
          }}

        {:ok, %{status: status, body: body}} ->
          {:error, "Dell token refresh failed with status #{status}: #{inspect(body)}"}

        {:error, reason} ->
          {:error, "Dell token refresh request failed: #{inspect(reason)}"}
      end
    end
  end

  defp do_refresh_token("intune", integration) do
    # Read per-tenant credentials from integration.auth_config (encrypted)
    client_id = get_in(integration.auth_config, ["client_id"])
    client_secret = get_in(integration.auth_config, ["client_secret"])
    refresh_token = get_refresh_token(integration)

    if is_nil(client_id) or is_nil(client_secret) or is_nil(refresh_token) do
      {:error, "Microsoft OAuth credentials or refresh token not configured for this integration"}
    else
      body = %{
        grant_type: "refresh_token",
        refresh_token: refresh_token,
        client_id: client_id,
        client_secret: client_secret,
        scope: "DeviceManagementManagedDevices.Read.All User.Read.All offline_access"
      }

      case Req.post("https://login.microsoftonline.com/common/oauth2/v2.0/token",
           form: body,
           headers: [{"content-type", "application/x-www-form-urlencoded"}]) do
        {:ok, %{status: 200, body: response}} ->
          {:ok, %{
            access_token: response["access_token"],
            refresh_token: response["refresh_token"] || refresh_token,
            expires_in: response["expires_in"] || 3600
          }}

        {:ok, %{status: status, body: body}} ->
          {:error, "Microsoft token refresh failed with status #{status}: #{inspect(body)}"}

        {:error, reason} ->
          {:error, "Microsoft token refresh request failed: #{inspect(reason)}"}
      end
    end
  end

  defp do_refresh_token("bamboohr", integration) do
    # Read per-tenant credentials from integration.auth_config (encrypted)
    # BambooHR requires Basic Authentication in the Authorization header
    client_id = get_in(integration.auth_config, ["client_id"])
    client_secret = get_in(integration.auth_config, ["client_secret"])
    refresh_token = get_refresh_token(integration)
    base_url = integration.base_url

    subdomain = extract_bamboohr_subdomain(base_url)

    cond do
      is_nil(client_id) or is_nil(client_secret) or is_nil(refresh_token) ->
        {:error, "BambooHR OAuth credentials or refresh token not configured for this integration"}

      is_nil(subdomain) ->
        {:error, "BambooHR subdomain not configured"}

      true ->
        # Create Basic Auth header (base64 encoded client_id:client_secret)
        credentials = Base.encode64("#{client_id}:#{client_secret}")

        body = %{
          grant_type: "refresh_token",
          refresh_token: refresh_token
        }

        case Req.post("https://#{subdomain}.bamboohr.com/token.php",
             form: body,
             headers: [
               {"authorization", "Basic #{credentials}"},
               {"content-type", "application/x-www-form-urlencoded"}
             ]) do
          {:ok, %{status: 200, body: response}} ->
            {:ok, %{
              access_token: response["access_token"],
              refresh_token: response["refresh_token"] || refresh_token,
              expires_in: response["expires_in"] || 3600
            }}

          {:ok, %{status: status, body: body}} ->
            {:error, "BambooHR token refresh failed with status #{status}: #{inspect(body)}"}

          {:error, reason} ->
            {:error, "BambooHR token refresh request failed: #{inspect(reason)}"}
        end
    end
  end

  defp do_refresh_token(provider, _integration) do
    {:error, "Token refresh not supported for provider: #{provider}"}
  end

  # Helper to extract refresh token from integration
  # The refresh_token is stored in auth_config (encrypted field)
  defp get_refresh_token(integration) do
    case integration.auth_config do
      %{"refresh_token" => token} when is_binary(token) -> token
      _ -> nil
    end
  end

  # Helper to extract BambooHR subdomain from base URL
  defp extract_bamboohr_subdomain(base_url) do
    base_url
    |> to_string()
    |> String.replace("https://", "")
    |> String.replace("http://", "")
    |> String.split(".")
    |> List.first()
  end

end
