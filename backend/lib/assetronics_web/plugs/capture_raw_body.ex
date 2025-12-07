defmodule AssetronicsWeb.Plugs.CaptureRawBody do
  @moduledoc """
  Plug to capture the raw request body for webhook signature verification.

  This plug reads the raw body and stores it in conn.assigns for later use,
  while preserving the body for normal parsing by other plugs.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    {:ok, body, conn} = read_body(conn)
    assign(conn, :raw_body, body)
  end
end