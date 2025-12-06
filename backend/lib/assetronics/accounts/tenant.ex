defmodule Assetronics.Accounts.Tenant do

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @status_values ~w(active suspended trial cancelled)
  @plan_values ~w(starter professional business enterprise)

  schema "tenants" do
    field :name, :string
    field :slug, :string
    field :status, :string, default: "trial"
    field :plan, :string, default: "starter"
    field :company_name, :string
    field :industry, :string
    field :employee_count_range, :string
    field :website, :string
    field :primary_contact_name, :string
    field :primary_contact_email, :string
    field :primary_contact_phone, :string
    field :billing_email, :string
    field :billing_address, :string
    field :settings, :map, default: %{}
    field :features, {:array, :string}, default: []
    field :trial_ends_at, :naive_datetime
    field :subscription_starts_at, :naive_datetime
    field :subscription_ends_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(tenant, attrs) do
    tenant
    |> cast(attrs, [
      :name,
      :slug,
      :status,
      :plan,
      :company_name,
      :industry,
      :employee_count_range,
      :website,
      :primary_contact_name,
      :primary_contact_email,
      :primary_contact_phone,
      :billing_email,
      :billing_address,
      :settings,
      :features,
      :trial_ends_at,
      :subscription_starts_at,
      :subscription_ends_at
    ])
    |> validate_required([:name, :slug])
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/, message: "must be lowercase alphanumeric with hyphens")
    |> validate_inclusion(:status, @status_values)
    |> validate_inclusion(:plan, @plan_values)
    |> validate_format(:primary_contact_email, ~r/@/, message: "must be a valid email")
    |> validate_format(:billing_email, ~r/@/, message: "must be a valid email")
    |> unique_constraint(:slug)
    |> generate_slug()
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :slug) do
      nil ->
        name = get_field(changeset, :name)
        if name do
          slug =
            name
            |> String.downcase()
            |> String.replace(~r/[^a-z0-9\s-]/, "")
            |> String.replace(~r/\s+/, "-")
          put_change(changeset, :slug, slug)
        else
          changeset
        end
      _ ->
        changeset
    end
  end
end
