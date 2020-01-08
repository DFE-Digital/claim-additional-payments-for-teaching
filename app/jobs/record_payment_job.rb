class RecordPaymentJob < ApplicationJob
  def perform(payment)
    payment.claims.each do |claim|
      Claim::GeckoboardEvent.new(claim, :paid, payment.updated_at).record
    end
  end
end
