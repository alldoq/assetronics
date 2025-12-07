defmodule Assetronics.Integrations.Adapters.Jamf.Api do
  @moduledoc """
  API client module for Jamf Pro integration.
  Handles all HTTP requests to Jamf Pro API endpoints.
  """

  alias Assetronics.Integrations.Adapters.Jamf.Auth
  alias Assetronics.Integrations.Integration
  require Logger

  @page_size 100

  @computer_sections [
    "GENERAL",
    "HARDWARE",
    "OPERATING_SYSTEM",
    "DISK_ENCRYPTION",
    "LOCAL_USER_ACCOUNTS",
    "USER_AND_LOCATION",
    "PURCHASING",
    "APPLICATIONS",
    "STORAGE",
    "PRINTERS",
    "SERVICES",
    "SECURITY",
    "SOFTWARE_UPDATES",
    "EXTENSION_ATTRIBUTES",
    "CONTENT_CACHING",
    "GROUP_MEMBERSHIPS",
    "IBEACONS",
    "LICENSED_SOFTWARE"
  ]

  @doc """
  Fetches a page of computers from Jamf Pro.
  """
  @spec fetch_computers(Integration.t(), String.t(), non_neg_integer()) ::
          {:ok, list(), non_neg_integer()} | {:error, term()}
  def fetch_computers(integration, token, page \\ 0) do
    base_url = Auth.normalize_url(integration.auth_config["endpoint"] || integration.base_url)
    section_params = Enum.map_join(@computer_sections, "&", fn s -> "section=#{s}" end)
    url = "#{base_url}/api/v1/computers-inventory?page=#{page}&page-size=#{@page_size}&#{section_params}"

    fetch_paginated_resource(url, token)
  end

  @doc """
  Fetches a page of mobile devices from Jamf Pro.
  """
  @spec fetch_mobile_devices(Integration.t(), String.t(), non_neg_integer()) ::
          {:ok, list(), non_neg_integer()} | {:error, term()}
  def fetch_mobile_devices(integration, token, page \\ 0) do
    base_url = Auth.normalize_url(integration.auth_config["endpoint"] || integration.base_url)
    url = "#{base_url}/api/v2/mobile-devices?page=#{page}&page-size=#{@page_size}"

    fetch_paginated_resource(url, token)
  end

  @doc """
  Fetches a single computer by ID from the classic API.
  """
  @spec fetch_computer_by_id(Integration.t(), String.t(), String.t() | integer()) ::
          {:ok, map()} | {:error, term()}
  def fetch_computer_by_id(integration, token, computer_id) do
    base_url = Auth.normalize_url(integration.auth_config["endpoint"] || integration.base_url)
    url = "#{base_url}/JSSResource/computers/id/#{computer_id}"
    headers = [Authorization: "Bearer #{token}", Accept: "application/json"]

    case Req.get(url, headers: headers, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        {:ok, body}

      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        case Jason.decode(body) do
          {:ok, parsed} -> {:ok, parsed}
          {:error, _} -> {:error, :invalid_json}
        end

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Fetches a single mobile device by ID from the classic API.
  """
  @spec fetch_mobile_device_by_id(Integration.t(), String.t(), String.t() | integer()) ::
          {:ok, map()} | {:error, term()}
  def fetch_mobile_device_by_id(integration, token, device_id) do
    base_url = Auth.normalize_url(integration.auth_config["endpoint"] || integration.base_url)
    url = "#{base_url}/JSSResource/mobiledevices/id/#{device_id}"
    headers = [Authorization: "Bearer #{token}", Accept: "application/json"]

    case Req.get(url, headers: headers, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        {:ok, body}

      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        case Jason.decode(body) do
          {:ok, parsed} -> {:ok, parsed}
          {:error, _} -> {:error, :invalid_json}
        end

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Fetches computer attachments.
  """
  @spec fetch_computer_attachments(Integration.t(), String.t(), String.t() | integer()) ::
          {:ok, list()} | {:error, term()}
  def fetch_computer_attachments(integration, token, computer_id) do
    base_url = Auth.normalize_url(integration.auth_config["endpoint"] || integration.base_url)
    url = "#{base_url}/api/v1/computers-inventory/#{computer_id}/attachments"
    headers = [Authorization: "Bearer #{token}", Accept: "application/json"]

    case Req.get(url, headers: headers, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: %{"results" => results}}} ->
        {:ok, results}

      {:ok, %{status: status}} when status in [404, 403, 405] ->
        {:ok, []}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Downloads a file from a given URL with authentication.
  """
  @spec download_file(String.t(), String.t()) ::
          {:ok, binary(), String.t()} | {:error, term()}
  def download_file(url, token) do
    headers = [Authorization: "Bearer #{token}"]

    case Req.get(url, headers: headers, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: body, headers: response_headers}} ->
        content_type = get_content_type(response_headers)
        {:ok, body, content_type}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Returns the page size used for pagination.
  """
  @spec page_size() :: non_neg_integer()
  def page_size, do: @page_size

  # Private functions

  defp fetch_paginated_resource(url, token) do
    headers = [Authorization: "Bearer #{token}", Accept: "application/json"]

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        items = body["results"] || []
        total_count = body["totalCount"] || 0
        {:ok, items, total_count}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Jamf API error: status #{status}, body: #{inspect(body)}")
        {:error, {:http_error, status}}

      {:error, reason} ->
        Logger.error("Jamf network error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp get_content_type(headers) do
    headers
    |> Enum.find(fn {key, _value} -> String.downcase(key) == "content-type" end)
    |> case do
      {_key, value} -> value
      nil -> "image/png"
    end
  end
end
