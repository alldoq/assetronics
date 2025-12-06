defmodule Mix.Tasks.Tenant.Seed do
  @moduledoc """
  Seeds default data for a tenant.

  ## Usage

      # Seed a specific tenant
      mix tenant.seed acme

      # Seed all existing tenants
      mix tenant.seed --all

  ## Examples

      mix tenant.seed acme
      mix tenant.seed techcorp
      mix tenant.seed --all

  """

  use Mix.Task

  @shortdoc "Seeds default categories and statuses for a tenant"

  @requirements ["app.start"]

  def run(args) do
    {opts, args, _} = OptionParser.parse(args, switches: [all: :boolean])

    cond do
      opts[:all] ->
        seed_all_tenants()

      length(args) == 1 ->
        tenant = List.first(args)
        seed_tenant(tenant)

      true ->
        Mix.shell().error("Usage: mix tenant.seed <tenant_slug> or mix tenant.seed --all")
        Mix.shell().error("")
        Mix.shell().error("Examples:")
        Mix.shell().error("  mix tenant.seed acme")
        Mix.shell().error("  mix tenant.seed --all")
    end
  end

  defp seed_tenant(tenant) do
    Mix.shell().info("Seeding tenant: #{tenant}")

    case Assetronics.Seeds.seed_tenant(tenant) do
      {:ok, message} ->
        Mix.shell().info(message)

      {:error, reason} ->
        Mix.shell().error("Failed to seed tenant: #{inspect(reason)}")
    end
  end

  defp seed_all_tenants do
    Mix.shell().info("Seeding all tenants...")

    # Get all tenants from database
    tenants = Assetronics.Repo.all(Assetronics.Tenants.Tenant)

    if Enum.empty?(tenants) do
      Mix.shell().info("No tenants found.")
    else
      Enum.each(tenants, fn tenant ->
        Mix.shell().info("")
        seed_tenant(tenant.slug)
      end)

      Mix.shell().info("")
      Mix.shell().info("Seeded #{length(tenants)} tenants")
    end
  end
end
