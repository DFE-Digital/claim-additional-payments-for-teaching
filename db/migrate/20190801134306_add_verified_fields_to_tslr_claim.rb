class AddVerifiedFieldsToTslrClaim < ActiveRecord::Migration[5.2]
  def change
    add_column :tslr_claims, :verified_fields, :text, array: true, default: []
  end
end
