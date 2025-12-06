defmodule Assetronics.Accounts.User do

  use Ecto.Schema
  import Ecto.Changeset

  alias Assetronics.Employees.Employee

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @roles ~w(super_admin admin manager employee viewer)
  @statuses ~w(active inactive locked)

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true
    field :first_name, :string
    field :last_name, :string
    field :role, :string, default: "employee"
    field :status, :string, default: "active"
    field :phone, :string
    field :avatar_url, :string
    field :timezone, :string, default: "UTC"
    field :locale, :string, default: "en"
    field :email_verified_at, :naive_datetime
    field :last_login_at, :naive_datetime
    field :last_login_ip, :string
    field :failed_login_attempts, :integer, default: 0
    field :locked_at, :naive_datetime
    field :password_reset_token, :string, redact: true
    field :password_reset_sent_at, :naive_datetime
    field :email_verification_token, :string, redact: true
    field :email_verification_sent_at, :naive_datetime
    field :metadata, :map
    belongs_to :employee, Employee

    timestamps()
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :first_name, :last_name, :role, :phone, :timezone, :locale])
    |> validate_required([:email, :password])
    |> validate_email()
    |> validate_password()
    |> validate_role()
    |> unique_constraint(:email)
    |> put_password_hash()
    |> put_email_verification_token()
  end

  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :phone, :avatar_url, :timezone, :locale, :metadata])
    |> validate_phone()
  end

  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_password()
    |> put_password_hash()
  end

  def password_reset_request_changeset(user) do
    token = generate_token(32)
    user  |> change() |> put_change(:password_reset_token, token)  |> put_change(:password_reset_sent_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
  end

  def password_reset_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_password()
    |> put_password_hash()
    |> put_change(:password_reset_token, nil)
    |> put_change(:password_reset_sent_at, nil)
  end

  def email_verification_changeset(user) do
    user
    |> change()
    |> put_change(:email_verified_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    |> put_change(:email_verification_token, nil)
    |> put_change(:email_verification_sent_at, nil)
  end

  def login_changeset(user, ip_address) do
    user
    |> change()
    |> put_change(:last_login_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    |> put_change(:last_login_ip, ip_address)
    |> put_change(:failed_login_attempts, 0)
  end

  def failed_login_changeset(user) do
    attempts = (user.failed_login_attempts || 0) + 1

    changeset = user
    |> change()
    |> put_change(:failed_login_attempts, attempts)
    if attempts >= 5 do
      put_change(changeset, :locked_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    else
      changeset
    end
  end

  def unlock_changeset(user) do
    user  |> change()  |> put_change(:locked_at, nil) |> put_change(:failed_login_attempts, 0)
  end

  def role_changeset(user, role) do
    user  |> change() |> put_change(:role, role)  |> validate_role()
  end

  def status_changeset(user, status) do
    user
    |> change()
    |> put_change(:status, status)
    |> validate_inclusion(:status, @statuses)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email address")
    |> validate_length(:email, max: 160)
    |> update_change(:email, &String.downcase/1)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 80)
    |> validate_format(:password, ~r/[a-z]/, message: "must contain at least one lowercase letter")
    |> validate_format(:password, ~r/[A-Z]/, message: "must contain at least one uppercase letter")
    |> validate_format(:password, ~r/[0-9]/, message: "must contain at least one number")
  end

  defp validate_role(changeset) do
    validate_inclusion(changeset, :role, @roles)
  end

  defp validate_phone(changeset) do
    changeset |> validate_format(:phone, ~r/^\+?[1-9]\d{1,14}$/, message: "must be a valid phone number")
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, password_hash: Argon2.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset

  defp put_email_verification_token(changeset) do
    token = generate_token(32)
    changeset  |> put_change(:email_verification_token, token) |> put_change(:email_verification_sent_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
  end

  defp generate_token(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end

  def verify_password(user, password) do
    Argon2.verify_pass(password, user.password_hash)
 end

  def locked?(user) do
    !is_nil(user.locked_at)
  end

  def active?(user) do
    user.status == "active" && !locked?(user)
  end

  def email_verified?(user) do
    !is_nil(user.email_verified_at)
  end

  def valid_password_reset_token?(user) do
    if is_nil(user.password_reset_sent_at) do
      false
    else
      NaiveDateTime.diff(NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second), user.password_reset_sent_at, :hour) < 1
    end
  end

  def roles, do: @roles
  def statuses, do: @statuses
end
