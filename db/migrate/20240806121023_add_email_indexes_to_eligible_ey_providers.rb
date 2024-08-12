class AddEmailIndexesToEligibleEyProviders < ActiveRecord::Migration[7.0]
  def change
    add_index :eligible_ey_providers, :primary_key_contact_email_address, name: "index_eligible_ey_providers_on_primary_contact_email_address"
    add_index :eligible_ey_providers, :secondary_contact_email_address
  end
end
