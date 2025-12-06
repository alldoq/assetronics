defmodule Assetronics.Repo.Migrations.RemoveTwilioFromTenantSettings do
  use Ecto.Migration

  def change do
    alter table(:tenant_settings) do
      remove :twilio_enabled
      remove :twilio_account_sid_encrypted
      remove :twilio_auth_token_encrypted
      remove :twilio_from_number
    end
  end
end
