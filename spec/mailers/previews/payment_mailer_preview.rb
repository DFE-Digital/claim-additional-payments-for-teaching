class PaymentMailerPreview < ActionMailer::Preview
  def confirmation
    payment = Payment.where.not(gross_value: nil).order(:created_at).last
    PaymentMailer.confirmation(payment, DateTime.now.to_time.to_i)
  end
end
