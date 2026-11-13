class RenameEligibleEytfiProviderPayeReferences < ActiveRecord::Migration[8.1]
  def change
    rename_column :eligible_eytfi_providers, :paye_reference, :paye_references
  end
end
