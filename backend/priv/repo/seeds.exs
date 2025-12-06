# Script for populating the database with test data
#
# Run with: mix run priv/repo/seeds.exs
#
# This will create:
# - 1 test tenant (acme)
# - Multiple test users with different roles
# - Locations, employees, assets, and workflows
#
# WARNING: This will create test data in your database!

alias Assetronics.Repo
alias Assetronics.Accounts
alias Assetronics.Accounts.{Tenant, User}
alias Assetronics.Locations
alias Assetronics.Employees
alias Assetronics.Assets
alias Assetronics.Workflows
alias Assetronics.Integrations
alias Triplex

IO.puts("\n🌱 Starting database seeding...\n")

# ============================================================================
# 1. CREATE TENANT
# ============================================================================

IO.puts("Creating tenant...")

tenant_attrs = %{
  name: "Acme Corporation",
  slug: "acme",
  status: "active",
  plan: "professional",
  subscription_starts_at: DateTime.utc_now() |> DateTime.truncate(:second),
  subscription_ends_at: DateTime.utc_now() |> DateTime.add(365, :day) |> DateTime.truncate(:second),
  features: ["advanced_analytics", "api_access", "custom_workflows"],
  settings: %{
    "timezone" => "America/New_York",
    "date_format" => "MM/DD/YYYY",
    "currency" => "USD"
  }
}

tenant = case Accounts.get_tenant_by_slug("acme") do
  {:ok, existing_tenant} ->
    IO.puts("  ✓ Tenant 'acme' already exists")
    existing_tenant
  {:error, :not_found} ->
    case Accounts.create_tenant(tenant_attrs) do
      {:ok, new_tenant} ->
        IO.puts("  ✓ Created tenant: #{new_tenant.name}")
        new_tenant
      {:error, reason} ->
        IO.puts("  ✗ Failed to create tenant: #{inspect(reason)}")
        raise "Failed to create tenant"
    end
end

IO.puts("  ✓ Tenant: #{tenant.name} (#{tenant.slug})")

# ============================================================================
# 2. CREATE USERS
# ============================================================================

IO.puts("\nCreating users with different roles...")

users_data = [
  %{
    email: "admin@acme.com",
    password: "Admin123!",
    first_name: "Alice",
    last_name: "Admin",
    role: "admin",
    phone: "+1-555-0101"
  },
  %{
    email: "manager@acme.com",
    password: "Manager123!",
    first_name: "Bob",
    last_name: "Manager",
    role: "manager",
    phone: "+1-555-0102"
  },
  %{
    email: "employee@acme.com",
    password: "Employee123!",
    first_name: "Charlie",
    last_name: "Employee",
    role: "employee",
    phone: "+1-555-0103"
  },
  %{
    email: "viewer@acme.com",
    password: "Viewer123!",
    first_name: "Diana",
    last_name: "Viewer",
    role: "viewer",
    phone: "+1-555-0104"
  }
]

users = Enum.map(users_data, fn user_attrs ->
  case Accounts.get_user_by_email(tenant.slug, user_attrs.email) do
    nil ->
      {:ok, user} = Accounts.create_user(tenant.slug, user_attrs)
      # Verify email immediately for testing
      {:ok, user} = Accounts.update_user(tenant.slug, user, %{
        email_verified_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      IO.puts("  ✓ Created #{user.role}: #{user.email}")
      user
    existing_user ->
      IO.puts("  ✓ User exists: #{existing_user.email}")
      existing_user
  end
end)

[admin, manager, employee_user, viewer] = users

# ============================================================================
# 3. CREATE LOCATIONS
# ============================================================================

IO.puts("\nCreating locations...")

locations_data = [
  %{
    name: "New York Office",
    location_type: "office",
    address_line1: "123 Main St",
    city: "New York",
    state_province: "NY",
    postal_code: "10001",
    country: "USA",
    status: "active"
  },
  %{
    name: "San Francisco Office",
    location_type: "office",
    address_line1: "456 Market St",
    city: "San Francisco",
    state_province: "CA",
    postal_code: "94102",
    country: "USA",
    status: "active"
  },
  %{
    name: "Main Warehouse",
    location_type: "warehouse",
    address_line1: "789 Industrial Pkwy",
    city: "Newark",
    state_province: "NJ",
    postal_code: "07102",
    country: "USA",
    status: "active"
  }
]

locations = Enum.map(locations_data, fn location_attrs ->
  {:ok, location} = Locations.create_location(tenant.slug, location_attrs)
  IO.puts("  ✓ Created location: #{location.name}")
  location
end)

[ny_office, sf_office, warehouse] = locations

# ============================================================================
# 4. CREATE EMPLOYEE RECORDS FOR USERS
# ============================================================================

IO.puts("\nCreating employee records for users...")

user_employees_data = [
  %{
    employee_id: "EMP-ADMIN",
    first_name: admin.first_name,
    last_name: admin.last_name,
    email: admin.email,
    phone: admin.phone,
    job_title: "IT Administrator",
    department: "IT",
    hire_date: ~D[2020-01-01],
    employment_status: "active",
    office_location_id: ny_office.id,
    work_location_type: "office"
  },
  %{
    employee_id: "EMP-MANAGER",
    first_name: manager.first_name,
    last_name: manager.last_name,
    email: manager.email,
    phone: manager.phone,
    job_title: "IT Manager",
    department: "IT",
    hire_date: ~D[2021-03-15],
    employment_status: "active",
    office_location_id: ny_office.id,
    work_location_type: "hybrid"
  },
  %{
    employee_id: "EMP-EMPLOYEE",
    first_name: employee_user.first_name,
    last_name: employee_user.last_name,
    email: employee_user.email,
    phone: employee_user.phone,
    job_title: "Software Developer",
    department: "Engineering",
    hire_date: ~D[2022-06-01],
    employment_status: "active",
    office_location_id: ny_office.id,
    work_location_type: "remote"
  },
  %{
    employee_id: "EMP-VIEWER",
    first_name: viewer.first_name,
    last_name: viewer.last_name,
    email: viewer.email,
    phone: viewer.phone,
    job_title: "Business Analyst",
    department: "Operations",
    hire_date: ~D[2023-01-10],
    employment_status: "active",
    office_location_id: sf_office.id,
    work_location_type: "office"
  }
]

user_employees = Enum.zip([admin, manager, employee_user, viewer], user_employees_data)
|> Enum.map(fn {user, employee_attrs} ->
  case Employees.create_employee(tenant.slug, employee_attrs) do
    {:ok, employee} ->
      # Link the user to the employee using Ecto.Changeset directly
      user
      |> Ecto.Changeset.change(%{employee_id: employee.id})
      |> Repo.update!(prefix: Triplex.to_prefix(tenant.slug))
      IO.puts("  ✓ Created employee record for #{user.role}: #{employee.first_name} #{employee.last_name} (#{employee.employee_id})")
      employee
    {:error, _changeset} ->
      # Employee exists, get by email and link
      {:ok, employee} = Employees.get_employee_by_email(tenant.slug, employee_attrs.email)
      user
      |> Ecto.Changeset.change(%{employee_id: employee.id})
      |> Repo.update!(prefix: Triplex.to_prefix(tenant.slug))
      IO.puts("  ✓ Employee exists for #{user.role}: #{employee.first_name} #{employee.last_name} (#{employee.employee_id})")
      employee
  end
end)

# ============================================================================
# 5. CREATE ADDITIONAL EMPLOYEES
# ============================================================================

IO.puts("\nCreating additional employees...")

employees_data = [
  %{
    employee_id: "EMP001",
    first_name: "John",
    last_name: "Doe",
    email: "john.doe@acme.com",
    phone: "+1-555-1001",
    job_title: "Software Engineer",
    department: "Engineering",
    hire_date: ~D[2023-01-15],
    employment_status: "active",
    office_location_id: ny_office.id,
    work_location_type: "hybrid"
  },
  %{
    employee_id: "EMP002",
    first_name: "Jane",
    last_name: "Smith",
    email: "jane.smith@acme.com",
    phone: "+1-555-1002",
    job_title: "Product Manager",
    department: "Product",
    hire_date: ~D[2022-06-01],
    employment_status: "active",
    office_location_id: sf_office.id,
    work_location_type: "office"
  },
  %{
    employee_id: "EMP003",
    first_name: "Mike",
    last_name: "Johnson",
    email: "mike.johnson@acme.com",
    phone: "+1-555-1003",
    job_title: "DevOps Engineer",
    department: "Engineering",
    hire_date: ~D[2023-03-20],
    employment_status: "active",
    office_location_id: ny_office.id,
    work_location_type: "remote"
  },
  %{
    employee_id: "EMP004",
    first_name: "Sarah",
    last_name: "Williams",
    email: "sarah.williams@acme.com",
    phone: "+1-555-1004",
    job_title: "UX Designer",
    department: "Design",
    hire_date: ~D[2023-07-10],
    employment_status: "active",
    office_location_id: sf_office.id,
    work_location_type: "hybrid"
  }
]

employees = Enum.map(employees_data, fn employee_attrs ->
  case Employees.create_employee(tenant.slug, employee_attrs) do
    {:ok, employee} ->
      IO.puts("  ✓ Created employee: #{employee.first_name} #{employee.last_name} (#{employee.employee_id})")
      employee
    {:error, _changeset} ->
      # Employee exists, get by email
      {:ok, employee} = Employees.get_employee_by_email(tenant.slug, employee_attrs.email)
      IO.puts("  ✓ Employee exists: #{employee.first_name} #{employee.last_name} (#{employee.employee_id})")
      employee
  end
end)

[john, jane, mike, sarah] = employees

# ============================================================================
# 6. CREATE ASSETS
# ============================================================================

IO.puts("\nCreating assets...")

assets_data = [
  %{
    asset_tag: "MBP-001",
    name: "MacBook Pro 16-inch",
    category: "laptop",
    make: "Apple",
    model: "MacBook Pro 16-inch 2024",
    serial_number: "C02XY1234567",
    purchase_date: ~D[2024-01-15],
    purchase_cost: Decimal.new("3499.00"),
    status: "assigned",
    condition: "new",
    location_id: ny_office.id,
    employee_id: john.id,
    warranty_expiry_date: ~D[2027-01-15]
  },
  %{
    asset_tag: "MBP-002",
    name: "MacBook Pro 14-inch",
    category: "laptop",
    make: "Apple",
    model: "MacBook Pro 14-inch 2024",
    serial_number: "C02XY2345678",
    purchase_date: ~D[2024-02-20],
    purchase_cost: Decimal.new("2499.00"),
    status: "assigned",
    condition: "new",
    location_id: sf_office.id,
    employee_id: jane.id,
    warranty_expiry_date: ~D[2027-02-20]
  },
  %{
    asset_tag: "MON-001",
    name: "Dell UltraSharp 27-inch",
    category: "monitor",
    make: "Dell",
    model: "U2723DE",
    serial_number: "CN-0ABC123-45678",
    purchase_date: ~D[2024-01-10],
    purchase_cost: Decimal.new("699.99"),
    status: "assigned",
    condition: "good",
    location_id: ny_office.id,
    employee_id: john.id
  },
  %{
    asset_tag: "IPH-001",
    name: "iPhone 15 Pro",
    category: "phone",
    make: "Apple",
    model: "iPhone 15 Pro",
    serial_number: "F17ABC123456",
    purchase_date: ~D[2023-11-01],
    purchase_cost: Decimal.new("1199.00"),
    status: "assigned",
    condition: "good",
    location_id: sf_office.id,
    employee_id: jane.id,
    warranty_expiry_date: ~D[2024-11-01]
  },
  %{
    asset_tag: "LAP-005",
    name: "Dell XPS 15",
    category: "laptop",
    make: "Dell",
    model: "XPS 15 9520",
    serial_number: "SVC-TAG-12345",
    purchase_date: ~D[2023-08-15],
    purchase_cost: Decimal.new("1899.00"),
    status: "in_stock",
    condition: "good",
    location_id: warehouse.id
  },
  %{
    asset_tag: "TAB-001",
    name: "iPad Pro 12.9-inch",
    category: "tablet",
    make: "Apple",
    model: "iPad Pro 12.9-inch (6th gen)",
    serial_number: "DMPXYZ123456",
    purchase_date: ~D[2023-12-01],
    purchase_cost: Decimal.new("1299.00"),
    status: "assigned",
    condition: "new",
    location_id: sf_office.id,
    employee_id: sarah.id
  }
]

assets = Enum.map(assets_data, fn asset_attrs ->
  {:ok, asset} = Assets.create_asset(tenant.slug, asset_attrs)
  IO.puts("  ✓ Created asset: #{asset.name} (#{asset.asset_tag}) - Status: #{asset.status}")
  asset
end)

# ============================================================================
# 7. CREATE WORKFLOWS
# ============================================================================

IO.puts("\nCreating workflows...")

workflows_data = [
  %{
    title: "New Employee Onboarding",
    description: "Complete onboarding process for new employees",
    workflow_type: "onboarding",
    status: "pending",
    steps: [
      %{
        "name" => "Create Email Account",
        "description" => "Set up corporate email and calendar",
        "order" => 1,
        "required" => true,
        "assigned_to_role" => "admin"
      },
      %{
        "name" => "Assign Equipment",
        "description" => "Provide laptop, phone, and other necessary equipment",
        "order" => 2,
        "required" => true,
        "assigned_to_role" => "manager"
      },
      %{
        "name" => "Security Training",
        "description" => "Complete mandatory security awareness training",
        "order" => 3,
        "required" => true,
        "assigned_to_role" => "employee"
      },
      %{
        "name" => "Setup Development Environment",
        "description" => "Install required software and tools",
        "order" => 4,
        "required" => false,
        "assigned_to_role" => "employee"
      }
    ]
  },
  %{
    title: "Asset Return Process",
    description: "Process for returning company equipment",
    workflow_type: "offboarding",
    status: "pending",
    steps: [
      %{
        "name" => "Inventory Check",
        "description" => "List all assets to be returned",
        "order" => 1,
        "required" => true
      },
      %{
        "name" => "Physical Return",
        "description" => "Return equipment to IT department",
        "order" => 2,
        "required" => true
      },
      %{
        "name" => "Data Wipe",
        "description" => "Securely wipe all data from devices",
        "order" => 3,
        "required" => true
      },
      %{
        "name" => "Update Inventory",
        "description" => "Mark assets as returned in system",
        "order" => 4,
        "required" => true
      }
    ]
  },
  %{
    title: "Equipment Repair",
    description: "Process for repairing damaged equipment",
    workflow_type: "maintenance",
    status: "pending",
    steps: [
      %{
        "name" => "Report Issue",
        "description" => "Document the problem with the equipment",
        "order" => 1,
        "required" => true
      },
      %{
        "name" => "Diagnostic",
        "description" => "Assess damage and determine repair options",
        "order" => 2,
        "required" => true
      },
      %{
        "name" => "Approve Repair",
        "description" => "Get approval for repair costs",
        "order" => 3,
        "required" => true
      },
      %{
        "name" => "Complete Repair",
        "description" => "Fix the equipment and test",
        "order" => 4,
        "required" => true
      }
    ]
  }
]

workflows = Enum.map(workflows_data, fn workflow_attrs ->
  {:ok, workflow} = Workflows.create_workflow(tenant.slug, workflow_attrs)
  IO.puts("  ✓ Created workflow: #{workflow.title} (#{length(workflow.steps)} steps)")
  workflow
end)

# ============================================================================
# 8. CREATE INTEGRATIONS
# ============================================================================

IO.puts("\nCreating integrations...")

integrations_data = [
  %{
    name: "BambooHR HRIS",
    provider: "bamboohr",
    integration_type: "hris",
    auth_type: "api_key",
    status: "active",
    api_key: "test_bamboohr_key_12345",
    config: %{
      "subdomain" => "acme"
    },
    sync_enabled: true,
    sync_frequency: "daily"
  },
  %{
    name: "QuickBooks Integration",
    provider: "quickbooks",
    integration_type: "finance",
    auth_type: "oauth2",
    status: "active",
    api_key: "test_qb_client_id_67890",
    access_token: "test_qb_access_token",
    refresh_token: "test_qb_refresh_token",
    config: %{
      "realm_id" => "123456789"
    },
    sync_enabled: false,
    sync_frequency: "weekly"
  },
  %{
    name: "Slack Notifications",
    provider: "slack",
    integration_type: "communication",
    auth_type: "bearer",
    status: "active",
    access_token: "xoxb-test-slack-bot-token",
    webhook_secret: "test_slack_webhook_secret",
    webhook_url: "https://hooks.slack.com/services/TEST/WEBHOOK",
    sync_config: %{
      "default_channel" => "#it-notifications"
    },
    sync_enabled: false
  }
]

integrations = Enum.map(integrations_data, fn integration_attrs ->
  {:ok, integration} = Integrations.create_integration(tenant.slug, integration_attrs)
  IO.puts("  ✓ Created integration: #{integration.name} (#{integration.provider})")
  integration
end)

# ============================================================================
# SUMMARY
# ============================================================================

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("✅ Database seeding completed successfully!")
IO.puts(String.duplicate("=", 60))

IO.puts("\n📊 Created:")
IO.puts("  • 1 Tenant: #{tenant.name} (#{tenant.slug})")
IO.puts("  • #{length(users)} Users with different roles")
IO.puts("  • #{length(locations)} Locations")
IO.puts("  • #{length(user_employees)} Employee records for users")
IO.puts("  • #{length(employees)} Additional employees")
IO.puts("  • #{length(assets)} Assets (#{Enum.count(assets, & &1.status == "assigned")} assigned, #{Enum.count(assets, & &1.status == "in_stock")} in stock)")
IO.puts("  • #{length(workflows)} Workflows")
IO.puts("  • #{length(integrations)} Integrations")

IO.puts("\n🔑 Test User Credentials:")
IO.puts("  Admin:    admin@acme.com / Admin123!")
IO.puts("  Manager:  manager@acme.com / Manager123!")
IO.puts("  Employee: employee@acme.com / Employee123!")
IO.puts("  Viewer:   viewer@acme.com / Viewer123!")

IO.puts("\n🌐 API Testing:")
IO.puts("  Tenant: acme")
IO.puts("  Base URL: http://localhost:4000/api/v1")
IO.puts("  Header: X-Tenant-ID: acme")

IO.puts("\n💡 Next Steps:")
IO.puts("  1. Start the server: mix phx.server")
IO.puts("  2. Login to get JWT token: POST /api/v1/auth/login")
IO.puts("  3. Import Insomnia collection: insomnia_collection.json")
IO.puts("  4. Test the API endpoints!")

IO.puts("\n")
