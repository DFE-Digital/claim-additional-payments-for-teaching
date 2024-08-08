class MakeEligibleEyProviderEmailsCitext < ActiveRecord::Migration[7.0]
  def change
    enable_extension "citext"

    reversible do |dir|
      dir.up do
        change_column :eligible_ey_providers, :primary_key_contact_email_address, :citext
        change_column :eligible_ey_providers, :secondary_contact_email_address, :citext
      end

      dir.down do
        change_column :eligible_ey_providers, :primary_key_contact_email_address, :string
        change_column :eligible_ey_providers, :secondary_contact_email_address, :string
      end
    end
  end
end
