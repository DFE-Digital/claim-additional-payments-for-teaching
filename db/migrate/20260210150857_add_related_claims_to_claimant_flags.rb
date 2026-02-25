class AddRelatedClaimsToClaimantFlags < ActiveRecord::Migration[8.1]
  def change
    add_column :claimant_flags, :related_claims, :string, array: true, default: []
  end
end
