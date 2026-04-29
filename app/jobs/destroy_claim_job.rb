# Destroys a single claim and all its dependent records.
# Enqueue via: DestroyClaimJob.perform_later(claim.id)
class DestroyClaimJob < ApplicationJob
  def perform(claim_id)
    claim = Claim.find(claim_id)
    claim.destroy!
  end
end
