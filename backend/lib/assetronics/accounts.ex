defmodule Assetronics.Accounts do
  @moduledoc """
  The Accounts context.

  Handles tenant (company/organization) management:
  - CRUD operations for tenants
  - Subscription management
  - Feature flags
  - Tenant creation with schema setup
  """

  import Ecto.Query, warn: false
  alias Assetronics.Repo
  alias Assetronics.Accounts.{Tenant, User}
  alias Assetronics.Settings
  alias Triplex

  require Logger

  @doc """
  Returns the list of tenants.

  ## Examples

      iex> list_tenants()
      [%Tenant{}, ...]

  """
  def list_tenants(opts \\ []) do
    query = from(t in Tenant, order_by: [asc: t.name])

    query
    |> apply_filters(opts)
    |> Repo.all()
  end

  @doc """
  Gets a single tenant.

  Raises `Ecto.NoResultsError` if the Tenant does not exist.

  ## Examples

      iex> get_tenant!("123")
      %Tenant{}

  """
  def get_tenant!(id), do: Repo.get!(Tenant, id)

  @doc """
  Gets a tenant by slug.

  ## Examples

      iex> get_tenant_by_slug("acme")
      {:ok, %Tenant{}}

  """
  def get_tenant_by_slug(slug) do
    case Repo.one(from(t in Tenant, where: t.slug == ^slug)) do
      nil -> {:error, :not_found}
      tenant -> {:ok, tenant}
    end
  end

  @doc """
  Creates a tenant and its PostgreSQL schema.

  ## Examples

      iex> create_tenant(%{name: "Acme Corp", slug: "acme"})
      {:ok, %Tenant{}}

  """
  def create_tenant(attrs \\ %{}) do
    # First create the tenant record
    result = %Tenant{}
      |> Tenant.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, tenant} ->
        # Create PostgreSQL schema using Triplex prefix format
        prefix = Triplex.to_prefix(tenant.slug)
        Repo.query!("CREATE SCHEMA IF NOT EXISTS #{prefix}")

        # Run tenant migrations using Ecto.Migrator directly
        migrations_path = Path.join([:code.priv_dir(:assetronics), "repo", "tenant_migrations"])
        Ecto.Migrator.run(Repo, migrations_path, :up, prefix: prefix, all: true)

        {:ok, tenant}

      error ->
        error
    end
  end

  @doc """
  Updates a tenant.

  ## Examples

      iex> update_tenant(tenant, %{name: "New Name"})
      {:ok, %Tenant{}}

  """
  def update_tenant(%Tenant{} = tenant, attrs) do
    tenant
    |> Tenant.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tenant and its PostgreSQL schema.

  WARNING: This will permanently delete all tenant data!

  ## Examples

      iex> delete_tenant(tenant)
      {:ok, %Tenant{}}

  """
  def delete_tenant(%Tenant{} = tenant) do
    Repo.transaction(fn ->
      # Drop PostgreSQL schema
      Triplex.drop(tenant.slug)

      # Delete tenant record
      Repo.delete!(tenant)
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tenant changes.

  ## Examples

      iex> change_tenant(tenant)
      %Ecto.Changeset{data: %Tenant{}}

  """
  def change_tenant(%Tenant{} = tenant, attrs \\ %{}) do
    Tenant.changeset(tenant, attrs)
  end

  @doc """
  Lists active tenants.

  ## Examples

      iex> list_active_tenants()
      [%Tenant{}, ...]

  """
  def list_active_tenants do
    query = from(t in Tenant, where: t.status == "active", order_by: [asc: t.name])
    Repo.all(query)
  end

  @doc """
  Lists tenants by plan.

  ## Examples

      iex> list_tenants_by_plan("professional")
      [%Tenant{}, ...]

  """
  def list_tenants_by_plan(plan) do
    query = from(t in Tenant, where: t.plan == ^plan, order_by: [asc: t.name])
    Repo.all(query)
  end

  @doc """
  Suspends a tenant.

  ## Examples

      iex> suspend_tenant(tenant)
      {:ok, %Tenant{}}

  """
  def suspend_tenant(%Tenant{} = tenant) do
    tenant
    |> Tenant.changeset(%{status: "suspended"})
    |> Repo.update()
  end

  @doc """
  Activates a tenant.

  ## Examples

      iex> activate_tenant(tenant)
      {:ok, %Tenant{}}

  """
  def activate_tenant(%Tenant{} = tenant) do
    tenant
    |> Tenant.changeset(%{status: "active"})
    |> Repo.update()
  end

  @doc """
  Updates tenant subscription.

  ## Examples

      iex> update_subscription(tenant, "professional", ~U[2024-12-31 23:59:59Z])
      {:ok, %Tenant{}}

  """
  def update_subscription(%Tenant{} = tenant, plan, subscription_ends_at) do
    tenant
    |> Tenant.changeset(%{
      plan: plan,
      subscription_ends_at: subscription_ends_at,
      subscription_starts_at: DateTime.utc_now()
    })
    |> Repo.update()
  end

  @doc """
  Checks if a tenant has a specific feature enabled.

  ## Examples

      iex> has_feature?(tenant, "advanced_analytics")
      true

  """
  def has_feature?(%Tenant{} = tenant, feature) do
    feature in (tenant.features || [])
  end

  @doc """
  Adds a feature to a tenant.

  ## Examples

      iex> add_feature(tenant, "advanced_analytics")
      {:ok, %Tenant{}}

  """
  def add_feature(%Tenant{} = tenant, feature) do
    features = Enum.uniq([feature | tenant.features || []])

    tenant
    |> Tenant.changeset(%{features: features})
    |> Repo.update()
  end

  @doc """
  Removes a feature from a tenant.

  ## Examples

      iex> remove_feature(tenant, "advanced_analytics")
      {:ok, %Tenant{}}

  """
  def remove_feature(%Tenant{} = tenant, feature) do
    features = List.delete(tenant.features || [], feature)

    tenant
    |> Tenant.changeset(%{features: features})
    |> Repo.update()
  end

  @doc """
  Lists tenants with expiring trials.

  Returns tenants where trial_ends_at is within the next N days.

  ## Examples

      iex> list_expiring_trials(7)
      [%Tenant{}, ...]

  """
  def list_expiring_trials(days \\ 7) do
    now = DateTime.utc_now()
    end_date = DateTime.add(now, days * 24 * 60 * 60, :second)

    query =
      from t in Tenant,
        where: t.status == "trial",
        where: t.trial_ends_at >= ^now,
        where: t.trial_ends_at <= ^end_date,
        order_by: [asc: t.trial_ends_at]

    Repo.all(query)
  end

  # Private functions

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:status, status}, query ->
        from(t in query, where: t.status == ^status)

      {:plan, plan}, query ->
        from(t in query, where: t.plan == ^plan)

      _, query ->
        query
    end)
  end

  # ============================================================================
  # User Management
  # ============================================================================

  @doc """
  Returns the list of users for a tenant.

  ## Examples

      iex> list_users("acme")
      [%User{}, ...]

  """
  def list_users(tenant, opts \\ []) do
    query = from(u in User, order_by: [asc: u.email])

    query
    |> apply_user_filters(opts)
    |> then(&Repo.all(&1, prefix: Triplex.to_prefix(tenant)))
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!("acme", "123")
      %User{}

  """
  def get_user!(tenant, id), do: Repo.get!(User, id, prefix: Triplex.to_prefix(tenant))

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("acme", "user@example.com")
      %User{}

  """
  def get_user_by_email(tenant, email) do
    query = from(u in User, where: u.email == ^String.downcase(email))
    Repo.one(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user("acme", %{email: "user@example.com", password: "password123"})
      {:ok, %User{}}

  """
  def create_user(tenant, attrs \\ %{}) do
    case %User{}
         |> User.registration_changeset(attrs)
         |> Repo.insert(prefix: Triplex.to_prefix(tenant)) do
      {:ok, user} ->
        # Seed default notification preferences for the new user
        case Settings.create_default_preferences_for_user(tenant, user.id) do
          {:ok, _preferences} ->
            Logger.info("Created default notification preferences for user #{user.id}")

          {:error, reason} ->
            Logger.error("Failed to create default notification preferences for user #{user.id}: #{inspect(reason)}")
        end

        {:ok, user}

      error ->
        error
    end
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user("acme", user, %{first_name: "John"})
      {:ok, %User{}}

  """
  def update_user(tenant, %User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user("acme", user)
      {:ok, %User{}}

  """
  def delete_user(tenant, %User{} = user) do
    Repo.delete(user, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Authenticates a user by email and password.

  Returns {:ok, user} if credentials are valid.
  Returns {:error, reason} if authentication fails.

  ## Examples

      iex> authenticate_user("acme", "user@example.com", "password123")
      {:ok, %User{}}

  """
  def authenticate_user(tenant, email, password) when is_binary(email) and is_binary(password) do
    user = get_user_by_email(tenant, email)

    cond do
      is_nil(user) ->
        # Perform dummy check to prevent timing attacks
        Argon2.no_user_verify()
        {:error, :invalid_credentials}

      User.locked?(user) ->
        {:error, :account_locked}

      user.status != "active" ->
        {:error, :account_inactive}

      User.verify_password(user, password) ->
        {:ok, user}

      true ->
        # Record failed login attempt
        user
        |> User.failed_login_changeset()
        |> Repo.update(prefix: Triplex.to_prefix(tenant))

        {:error, :invalid_credentials}
    end
  end

  @doc """
  Records a successful login.

  ## Examples

      iex> record_login("acme", user, "192.168.1.1")
      {:ok, %User{}}

  """
  def record_login(tenant, %User{} = user, ip_address) do
    user
    |> User.login_changeset(ip_address)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Changes a user's password.

  ## Examples

      iex> change_password("acme", user, %{password: "newpassword"})
      {:ok, %User{}}

  """
  def change_password(tenant, %User{} = user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Requests a password reset for a user.

  ## Examples

      iex> request_password_reset("acme", "user@example.com")
      {:ok, %User{}}

  """
  def request_password_reset(tenant, email) when is_binary(email) do
    case get_user_by_email(tenant, email) do
      nil ->
        # Don't reveal if email exists
        {:error, :not_found}

      user ->
        user
        |> User.password_reset_request_changeset()
        |> Repo.update(prefix: Triplex.to_prefix(tenant))
    end
  end

  @doc """
  Resets a user's password using a reset token.

  ## Examples

      iex> reset_password("acme", token, %{password: "newpassword"})
      {:ok, %User{}}

  """
  def reset_password(tenant, token, attrs) do
    query = from(u in User, where: u.password_reset_token == ^token)

    case Repo.one(query, prefix: Triplex.to_prefix(tenant)) do
      nil ->
        {:error, :invalid_token}

      user ->
        if User.valid_password_reset_token?(user) do
          user
          |> User.password_reset_changeset(attrs)
          |> Repo.update(prefix: Triplex.to_prefix(tenant))
        else
          {:error, :token_expired}
        end
    end
  end

  @doc """
  Verifies a user's email address.

  ## Examples

      iex> verify_email("acme", token)
      {:ok, %User{}}

  """
  def verify_email(tenant, token) do
    query = from(u in User, where: u.email_verification_token == ^token)

    case Repo.one(query, prefix: Triplex.to_prefix(tenant)) do
      nil ->
        {:error, :invalid_token}

      user ->
        user
        |> User.email_verification_changeset()
        |> Repo.update(prefix: Triplex.to_prefix(tenant))
    end
  end

  @doc """
  Updates a user's role.

  ## Examples

      iex> update_user_role("acme", user, "admin")
      {:ok, %User{}}

  """
  def update_user_role(tenant, %User{} = user, role) do
    user
    |> User.role_changeset(role)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Updates a user's status.

  ## Examples

      iex> update_user_status("acme", user, "inactive")
      {:ok, %User{}}

  """
  def update_user_status(tenant, %User{} = user, status) do
    user
    |> User.status_changeset(status)
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Unlocks a locked user account.

  ## Examples

      iex> unlock_user("acme", user)
      {:ok, %User{}}

  """
  def unlock_user(tenant, %User{} = user) do
    user
    |> User.unlock_changeset()
    |> Repo.update(prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Lists users by role.

  ## Examples

      iex> list_users_by_role("acme", "admin")
      [%User{}, ...]

  """
  def list_users_by_role(tenant, role) do
    query = from(u in User, where: u.role == ^role, order_by: [asc: u.email])
    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Lists active users.

  ## Examples

      iex> list_active_users("acme")
      [%User{}, ...]

  """
  def list_active_users(tenant) do
    query = from(u in User, where: u.status == "active" and is_nil(u.locked_at), order_by: [asc: u.email])
    Repo.all(query, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets tenant by slug (raises if not found).
  """
  def get_tenant_by_slug!(slug) do
    case get_tenant_by_slug(slug) do
      {:ok, tenant} -> tenant
      {:error, :not_found} -> raise Ecto.NoResultsError, queryable: Tenant
    end
  end

  @doc """
  Gets tenant usage statistics.

  Returns counts of users, assets, employees, locations, workflows, and integrations.
  """
  def get_tenant_usage(tenant_slug) do
    prefix = Triplex.to_prefix(tenant_slug)

    %{
      user_count: Repo.one(from(u in User, select: count(u.id)), prefix: prefix) || 0,
      asset_count: Repo.one(from(a in "assets", select: count(a.id)), prefix: prefix) || 0,
      employee_count: Repo.one(from(e in "employees", select: count(e.id)), prefix: prefix) || 0,
      location_count: Repo.one(from(l in "locations", select: count(l.id)), prefix: prefix) || 0,
      workflow_count: Repo.one(from(w in "workflows", select: count(w.id)), prefix: prefix) || 0,
      integration_count: Repo.one(from(i in "integrations", select: count(i.id)), prefix: prefix) || 0
    }
  end

  # Private user filter functions

  defp apply_user_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:role, role}, query ->
        from(u in query, where: u.role == ^role)

      {:status, status}, query ->
        from(u in query, where: u.status == ^status)

      {:email, email}, query ->
        from(u in query, where: ilike(u.email, ^"%#{email}%"))

      _, query ->
        query
    end)
  end
end
