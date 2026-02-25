class RemovePreviousClaimIdFromRelatedClaims < ActiveRecord::Migration[8.1]
  def change
    remove_column :claimant_flags, :previous_claim_id, :uuid
  end
end
