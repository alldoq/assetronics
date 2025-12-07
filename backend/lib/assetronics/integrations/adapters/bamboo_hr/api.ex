defmodule Assetronics.Integrations.Adapters.BambooHR.Api do
  @moduledoc """
  Handles API communication with BambooHR endpoints.

  Provides functions for fetching employee data, testing connections,
  and managing HTTP requests.
  """

  require Logger

  @doc """
  Tests the connection to BambooHR API.

  Uses the /meta/users endpoint for basic connectivity check.
  """
  def test_connection(client) do
    Logger.info("Testing BambooHR connection with /meta/users endpoint")

    case Tesla.get(client, "/meta/users") do
      {:ok, %Tesla.Env{status: 200}} ->
        Logger.info("Successfully connected to BambooHR via OAuth")
        {:ok, %{status: "connected", message: "Successfully connected to BambooHR"}}

      {:ok, %Tesla.Env{status: 401, body: body}} ->
        Logger.error("BambooHR connection unauthorized: #{inspect(body)}")
        {:error, :unauthorized}

      {:ok, %Tesla.Env{status: 403, body: body}} ->
        Logger.error("BambooHR connection forbidden: #{inspect(body)}")
        {:error, :forbidden}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error("BambooHR connection failed with status #{status}: #{inspect(body)}")
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        Logger.error("BambooHR connection error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetches employee data from BambooHR.

  Combines data from Custom Report API and Directory API to get
  comprehensive employee information including photos.
  """
  def fetch_employees(client) do
    # 1. Fetch detailed data using Custom Report API
    # This provides critical fields like hireDate, status, email, PII
    report_endpoint = "/reports/custom?format=json"

    report_fields = [
      "id", "employeeNumber", "firstName", "lastName",
      "workEmail", "email", "jobTitle", "department", "division", "location",
      "supervisorEmail", "hireDate", "terminationDate", "employmentStatus",
      "mobilePhone", "workPhone", "dateOfBirth", "ssn", "gender",
      "maritalStatus", "address1", "address2", "city", "state", "zipcode", "country"
    ]

    report_body = %{"title" => "Assetronics Sync", "fields" => report_fields}

    Logger.info("Fetching BambooHR employees details (Custom Report)...")

    with {:ok, report_data} <- post_request(client, report_endpoint, report_body),
         # 2. Fetch basic data (including photos) using Directory API
         # Photos are often only available here or require specific permissions in reports
         {:ok, directory_data} <- get_request(client, "/employees/directory") do

      Logger.info("Fetched #{length(report_data)} detailed records and #{length(directory_data)} directory records")

      # 3. Merge data
      # Create a map of directory data keyed by ID for O(1) lookup
      dir_map = Map.new(directory_data, fn emp -> {to_string(emp["id"]), emp} end)

      merged_data = Enum.map(report_data, fn emp ->
        id = to_string(emp["id"])
        dir_emp = Map.get(dir_map, id, %{})

        # Merge, preferring report data but filling gaps (like photoUrl) from directory
        merged = Map.merge(dir_emp, emp)

        # Preserve photoUrl from directory if report doesn't have a valid value
        photo_url = case merged["photoUrl"] do
          url when url in [nil, "", "null"] -> dir_emp["photoUrl"]
          url -> url
        end

        Map.put(merged, "photoUrl", photo_url)
      end)

      {:ok, merged_data}
    else
      error -> error
    end
  end

  @doc """
  Downloads employee photo from BambooHR or CloudFront CDN.
  """
  def download_photo(photo_url) do
    # Use a simple HTTP client without API auth for CloudFront-signed image URLs
    # CloudFront URLs are already signed and don't need API authentication
    image_client = Tesla.client([
      {Tesla.Middleware.Timeout, timeout: 30_000}
    ])

    case Tesla.get(image_client, photo_url) do
      {:ok, %Tesla.Env{status: 200, body: image_data, headers: headers}} ->
        # Get content type from headers
        content_type = Enum.find_value(headers, "image/jpeg", fn
          {"content-type", val} -> val
          _ -> nil
        end)

        {:ok, image_data, content_type}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private functions

  defp post_request(client, endpoint, body) do
    case Tesla.post(client, endpoint, body) do
      {:ok, %Tesla.Env{status: 200, body: %{"employees" => employees}}} ->
        {:ok, employees}

      {:ok, %Tesla.Env{status: 200, body: body}} when is_list(body) ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error("BambooHR POST #{endpoint} failed: #{status}")
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_request(client, endpoint) do
    case Tesla.get(client, endpoint) do
      {:ok, %Tesla.Env{status: 200, body: %{"employees" => employees}}} ->
        {:ok, employees}

      {:ok, %Tesla.Env{status: 200, body: body}} when is_list(body) ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error("BambooHR GET #{endpoint} failed: #{status}")
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end