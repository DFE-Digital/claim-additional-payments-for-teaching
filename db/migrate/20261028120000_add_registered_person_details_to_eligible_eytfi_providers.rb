class AddRegisteredPersonDetailsToEligibleEytfiProviders < ActiveRecord::Migration[8.1]
  def change
    add_column :eligible_eytfi_providers, :registered_person_name, :text
    add_column :eligible_eytfi_providers, :telephone_number, :text
    add_column :eligible_eytfi_providers, :paye_reference, :text
    add_column :eligible_eytfi_providers, :multiple_nurseries, :boolean
  end
end
