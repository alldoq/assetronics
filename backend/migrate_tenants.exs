alias Assetronics.{Repo, Accounts.Tenant}

# Start apps
Application.ensure_all_started(:assetronics)

# Get or create ACME tenant
tenant = case Repo.get_by(Tenant, slug: "acme") do
  nil ->
    IO.puts "Creating ACME tenant..."
    {:ok, t} = %Tenant{}
    |> Tenant.changeset(%{name: "Acme Corp", slug: "acme", plan: "enterprise"})
    |> Repo.insert()
    
    # Create schema
    Triplex.create("acme")
    t
    
  t -> 
    IO.puts "Found ACME tenant."
    t
end

# Run migrations
IO.puts "Migrating tenant: #{tenant.slug}"
Triplex.migrate(tenant.slug)
IO.puts "Migration complete."
