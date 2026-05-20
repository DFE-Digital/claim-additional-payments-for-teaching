class AddMaxClaimsToEligibleEytfiProviders < ActiveRecord::Migration[8.1]
  def change
    add_column :eligible_eytfi_providers, :max_claims, :integer, null: false
  end
end
