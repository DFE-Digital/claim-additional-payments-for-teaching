class AddPrimaryContactEmailAddressToEligileFeProviders < ActiveRecord::Migration[7.0]
  def change
    add_column :eligible_fe_providers, :primary_key_contact_email_address, :string
  end
end
