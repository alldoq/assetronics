defmodule Assetronics.Integrations.Adapters.Jamf.Auth do
  @moduledoc """
  Authentication module for Jamf Pro integration.
  Handles OAuth 2.0 client credentials flow.
  """

  alias Assetronics.Integrations.Integration
  require Logger

  @doc """
  Obtains an OAuth access token from Jamf Pro using client credentials flow.

  Returns {:ok, token} on success or {:error, reason} on failure.
  """
  @spec get_token(Integration.t()) :: {:ok, String.t()} | {:error, String.t()}
  def get_token(%Integration{} = integration) do
    endpoint = normalize_url(integration.auth_config["endpoint"] || integration.base_url)
    client_id = integration.auth_config["client_id"]
    client_secret = integration.auth_config["client_secret"]

    url = "#{endpoint}/api/oauth/token"

    body = %{
      "client_id" => client_id,
      "client_secret" => client_secret,
      "grant_type" => "client_credentials"
    }

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Accept", "application/json"}
    ]

    case Req.post(url, form: body, headers: headers) do
      {:ok, %{status: 200, body: %{"access_token" => token}}} ->
        {:ok, token}

      {:ok, %{status: status, body: body}} ->
        {:error, "Jamf OAuth failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Jamf OAuth connection error: #{inspect(reason)}"}
    end
  end

  @doc """
  Normalizes URL by removing trailing slashes.
  """
  @spec normalize_url(String.t()) :: String.t()
  def normalize_url(url), do: String.trim_trailing(url, "/")
end
