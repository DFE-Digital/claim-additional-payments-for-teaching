require "geckoboard"

class RecordSubmittedClaimJob < ApplicationJob
  def perform(claim)
    Claim::GeckoboardEvent.new(claim, :submitted, claim.submitted_at).record
  end
end
