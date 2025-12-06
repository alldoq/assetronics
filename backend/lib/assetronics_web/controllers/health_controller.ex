defmodule AssetronicsWeb.HealthController do
  use AssetronicsWeb, :controller

  @doc """
  Health check endpoint.

  Returns 200 OK if the application is healthy.
  """
  def index(conn, _params) do
    # You can add more health checks here:
    # - Database connectivity
    # - External service status
    # - Disk space
    # etc.

    json(conn, %{
      status: "ok",
      timestamp: DateTime.utc_now(),
      version: Application.spec(:assetronics, :vsn) |> to_string()
    })
  end
end
