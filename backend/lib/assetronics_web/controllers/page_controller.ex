defmodule AssetronicsWeb.PageController do
  use AssetronicsWeb, :controller

  def home(conn, _params) do
    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, Path.join([Application.app_dir(:assetronics, "priv/static"), "landing.html"]))
  end
end
