class PaymentMailerPreview < ActionMailer::Preview
  def confirmation_for_single_claim
    PaymentMailer.confirmation(payment(claims_count: "= 1"))
  end

  def confirmation_for_multiple_claims
    PaymentMailer.confirmation(payment(claims_count: "> 1"))
  end

  private

  def payment(claims_count:)
    Payment
      .where
      .not(
        award_amount: nil,
        gross_value: nil,
        national_insurance: nil,
        employers_national_insurance: nil,
        tax: nil,
        net_pay: nil,
        gross_pay: nil
      ).joins(:claims)
      .group(:id)
      .having("COUNT(claims.id) #{claims_count}")
      .order(:created_at)
      .last
  end
end
