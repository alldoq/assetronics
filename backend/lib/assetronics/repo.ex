defmodule Assetronics.Repo do
  use Ecto.Repo,
    otp_app: :assetronics,
    adapter: Ecto.Adapters.Postgres
end
