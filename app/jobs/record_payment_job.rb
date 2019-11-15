class RecordPaymentJob < ApplicationJob
  def perform(claim)
    Claim::GeckoboardEvent.new(claim, :paid, claim.payment.updated_at).record
  end
end
