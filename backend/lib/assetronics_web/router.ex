defmodule AssetronicsWeb.Router do
  use AssetronicsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug, origin: ["http://localhost:3000", "http://localhost:5173"]
  end

  pipeline :api_authenticated do
    plug :accepts, ["json"]
    plug CORSPlug, origin: ["http://localhost:3000", "http://localhost:5173"]
    plug AssetronicsWeb.Plugs.TenantResolver
    plug AssetronicsWeb.Plugs.AuthPlug
  end

  pipeline :api_agent do
    plug :accepts, ["json"]
    plug AssetronicsWeb.Plugs.TenantResolver
  end

  pipeline :webhook do
    plug :accepts, ["json"]
    plug AssetronicsWeb.Plugs.CaptureRawBody
  end

  # Landing page route
  scope "/", AssetronicsWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Agent routes
  scope "/api/v1/agent", AssetronicsWeb do
    pipe_through :api_agent
    
    post "/checkin", AgentController, :checkin
    post "/scan", AgentController, :scan
  end

  # Webhook routes (with raw body capture)
  scope "/api/v1", AssetronicsWeb do
    pipe_through :webhook

    post "/webhooks/bamboohr", WebhookController, :bamboohr
    post "/webhooks/jamf", WebhookController, :jamf
    get "/webhooks/okta", WebhookController, :okta_verify
    post "/webhooks/okta", WebhookController, :okta
    post "/webhooks/precoro", WebhookController, :precoro
  end

  # Public API routes (no authentication required)
  scope "/api/v1", AssetronicsWeb do
    pipe_through :api

    # OAuth Callbacks
    get "/oauth/callback", OAuthController, :callback

    # Health check
    get "/health", HealthController, :index

    # Authentication
    scope "/auth" do
      post "/login", SessionController, :login
      post "/refresh", SessionController, :refresh
      post "/register", UserController, :create

      # Password reset
      post "/password/reset", PasswordController, :request_reset
      post "/password/confirm", PasswordController, :confirm_reset
      post "/email/verify", PasswordController, :verify_email
    end
  end

  # Tenant-scoped API routes (authentication required)
  scope "/api/v1", AssetronicsWeb do
    pipe_through :api_authenticated

    # Authenticated auth routes
    scope "/auth" do
      post "/logout", SessionController, :logout
      get "/me", SessionController, :me
      patch "/password/change", PasswordController, :change_password
    end

    # Users
    resources "/users", UserController, except: [:new, :edit] do
      patch "/role", UserController, :update_role
      patch "/status", UserController, :update_status
      post "/unlock", UserController, :unlock
      post "/avatar", FileController, :upload_avatar
    end

    # Files
    resources "/files", FileController, only: [:index, :show, :create, :delete]

    # Categories
    resources "/categories", CategoryController, except: [:new, :edit]

    # Organizations
    resources "/organizations", OrganizationController, except: [:new, :edit]

    # Departments
    resources "/departments", DepartmentController, except: [:new, :edit]

    # Statuses
    resources "/statuses", StatusController, except: [:new, :edit]

    # Assets
    resources "/assets", AssetController, except: [:new, :edit] do
      post "/assign", AssetController, :assign
      post "/return", AssetController, :return
      post "/transfer", AssetController, :transfer
      get "/history", AssetController, :history
      post "/photos", FileController, :upload_asset_photo
      get "/transactions", TransactionController, :asset_transactions
      get "/label", AssetController, :label
    end

    get "/assets/search", AssetController, :search
    post "/assets/batch-labels", AssetController, :batch_labels

    # Transactions
    resources "/transactions", TransactionController, only: [:index, :show]

    # Employees
    resources "/employees", EmployeeController, except: [:new, :edit] do
      post "/terminate", EmployeeController, :terminate
      post "/reactivate", EmployeeController, :reactivate
      get "/assets", EmployeeController, :assets
    end

    # Locations
    resources "/locations", LocationController, except: [:new, :edit] do
      post "/activate", LocationController, :activate
      post "/deactivate", LocationController, :deactivate
      get "/assets", LocationController, :assets
      get "/employees", LocationController, :employees
    end

    # Workflows
    get "/workflows/templates", WorkflowController, :templates
    post "/workflows/from-template", WorkflowController, :create_from_template
    get "/workflows/overdue", WorkflowController, :overdue

    resources "/workflows", WorkflowController, except: [:new, :edit] do
      post "/start", WorkflowController, :start
      post "/complete", WorkflowController, :complete
      post "/cancel", WorkflowController, :cancel
      post "/advance", WorkflowController, :advance_step
      post "/attachments", FileController, :upload_workflow_attachment
    end

    # Integrations
    get "/integrations/auth/connect", IntegrationAuthController, :connect

    resources "/integrations", IntegrationController, except: [:new, :edit] do
      post "/sync", IntegrationController, :trigger_sync
      post "/test", IntegrationController, :test_connection
      post "/enable-sync", IntegrationController, :enable_sync
      post "/disable-sync", IntegrationController, :disable_sync
      get "/sync-history", IntegrationController, :sync_history
    end

    # Tenants (admin only - TODO: add admin authorization)
    resources "/tenants", TenantController, only: [:show, :update] do
      get "/usage", TenantController, :usage
      get "/features", TenantController, :features
      post "/features/add", TenantController, :add_feature
      post "/features/remove", TenantController, :remove_feature
      post "/subscription", TenantController, :update_subscription
    end

    # Dashboard
    get "/dashboard", DashboardController, :index

    # Settings
    get "/settings", SettingsController, :show
    patch "/settings", SettingsController, :update

    # User Notification Preferences
    get "/preferences/notifications", UserPreferencesController, :index
    get "/preferences/notifications/:type", UserPreferencesController, :show
    patch "/preferences/notifications/:type", UserPreferencesController, :update

    # Reports
    scope "/reports" do
      get "/license-reclamation", ReportController, :license_reclamation
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:assetronics, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: AssetronicsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
