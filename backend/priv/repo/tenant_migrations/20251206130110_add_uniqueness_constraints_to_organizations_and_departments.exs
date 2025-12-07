defmodule Assetronics.Repo.Migrations.AddUniquenessConstraintsToOrganizationsAndDepartments do
  use Ecto.Migration

  def up do
    # Create case-insensitive unique index on organizations.name
    # Uses LOWER() to ensure "IT Department", "it department", "IT DEPARTMENT" are all treated as duplicates
    execute """
    CREATE UNIQUE INDEX organizations_name_lower_idx ON organizations (LOWER(name))
    """

    # Create case-insensitive unique index on departments.name
    execute """
    CREATE UNIQUE INDEX departments_name_lower_idx ON departments (LOWER(name))
    """
  end

  def down do
    # Drop the unique indexes
    execute "DROP INDEX IF EXISTS organizations_name_lower_idx"
    execute "DROP INDEX IF EXISTS departments_name_lower_idx"
  end
end
