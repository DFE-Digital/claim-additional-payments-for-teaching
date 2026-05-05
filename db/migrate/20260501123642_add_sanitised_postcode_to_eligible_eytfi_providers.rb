class AddSanitisedPostcodeToEligibleEytfiProviders < ActiveRecord::Migration[8.1]
  def change
    add_column :eligible_eytfi_providers, :sanitised_postcode, :text
  end
end
