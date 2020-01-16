class RecordClaimEventJob < ApplicationJob
  def perform(claim_ids, event_type, performed_at_method)
    claims = Claim.where(id: claim_ids)
    Claim::GeckoboardEvent.new(claims, event_type, performed_at_method).record
  end
end
