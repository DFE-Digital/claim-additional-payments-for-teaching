class ClaimMailerPreview < ActionMailer::Preview
  def submitted
    ClaimMailer.submitted(Claim.submitted.last)
  end

  def approved
    ClaimMailer.approved(Claim.approved.last)
  end

  def rejected
    ClaimMailer.rejected(Claim.rejected.last)
  end

  def payment_confirmation
    payment = Payment.where.not(gross_value: nil).last
    ClaimMailer.payment_confirmation(payment.claim, DateTime.now.to_time.to_i)
  end
end
