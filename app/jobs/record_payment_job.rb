class RecordPaymentJob < ApplicationJob
  def perform(payment)
    Claim::GeckoboardEvent.new(payment.claim, :paid, payment.updated_at).record
  end
end
