class RecordPaymentJob < ApplicationJob
  def perform(claim_ids)
    claims = Claim.where(id: claim_ids)
    Claim::GeckoboardEvent.new(claims, :paid, :scheduled_payment_date).record
  end
end
