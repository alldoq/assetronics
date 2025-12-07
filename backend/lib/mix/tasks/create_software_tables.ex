defmodule Mix.Tasks.CreateSoftwareTables do
  use Mix.Task

  @shortdoc "Creates software_licenses tables in acme tenant"
  def run(_args) do
    Mix.Task.run("app.start")
    
    alias Assetronics.Repo
    
    # Create tables in acme schema
    Ecto.Adapters.SQL.query!(Repo, """
    CREATE TABLE IF NOT EXISTS acme.software_licenses (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      name varchar(255) NOT NULL,
      vendor varchar(255) NOT NULL,
      description text,
      total_seats integer NOT NULL DEFAULT 0,
      annual_cost_encrypted bytea,
      annual_cost_hash bytea,
      cost_per_seat_encrypted bytea,
      cost_per_seat_hash bytea,
      purchase_date date,
      expiration_date date,
      status varchar(255) NOT NULL DEFAULT 'active',
      license_key_encrypted bytea,
      license_key_hash bytea,
      sso_app_id varchar(255),
      integration_id uuid,
      inserted_at timestamp NOT NULL DEFAULT NOW(),
      updated_at timestamp NOT NULL DEFAULT NOW()
    );
    """, [])
    
    Ecto.Adapters.SQL.query!(Repo, """
    CREATE INDEX IF NOT EXISTS software_licenses_status_index ON acme.software_licenses (status);
    """, [])
    
    Ecto.Adapters.SQL.query!(Repo, """
    CREATE INDEX IF NOT EXISTS software_licenses_vendor_index ON acme.software_licenses (vendor);
    """, [])
    
    Ecto.Adapters.SQL.query!(Repo, """
    CREATE INDEX IF NOT EXISTS software_licenses_expiration_date_index ON acme.software_licenses (expiration_date);
    """, [])
    
    Ecto.Adapters.SQL.query!(Repo, """
    CREATE UNIQUE INDEX IF NOT EXISTS software_licenses_name_vendor_index ON acme.software_licenses (name, vendor);
    """, [])
    
    # Create assignments table
    Ecto.Adapters.SQL.query!(Repo, """
    CREATE TABLE IF NOT EXISTS acme.software_assignments (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      employee_id uuid NOT NULL,
      software_license_id uuid NOT NULL,
      assigned_at timestamp NOT NULL,
      last_used_at timestamp,
      status varchar(255) NOT NULL DEFAULT 'active',
      inserted_at timestamp NOT NULL DEFAULT NOW(),
      updated_at timestamp NOT NULL DEFAULT NOW()
    );
    """, [])
    
    Ecto.Adapters.SQL.query!(Repo, """
    CREATE INDEX IF NOT EXISTS software_assignments_employee_id_index ON acme.software_assignments (employee_id);
    """, [])
    
    Ecto.Adapters.SQL.query!(Repo, """
    CREATE INDEX IF NOT EXISTS software_assignments_software_license_id_index ON acme.software_assignments (software_license_id);
    """, [])
    
    Ecto.Adapters.SQL.query!(Repo, """
    CREATE INDEX IF NOT EXISTS software_assignments_status_index ON acme.software_assignments (status);
    """, [])
    
    IO.puts("✓ Software tables created successfully in acme schema")
  end
end
