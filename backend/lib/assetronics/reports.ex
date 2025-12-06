defmodule Assetronics.Reports do
  @moduledoc """
  Context for generating analytics and reports.
  """

  alias Assetronics.Reports.LicenseReclamation

  def license_reclamation(tenant, days \\ 90) do
    LicenseReclamation.generate(tenant, days)
  end
end
