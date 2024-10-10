module PaymentMailerHelper
  def breakdown_of_payment_bullets(payment)
    bullets = []

    !payment.claims.one? && payment.claims.each do |claim|
      bullets << "#{I18n.t("#{claim.policy.locale_key}.claim_amount_description")}: #{number_to_currency(claim.award_amount)}"
    end

    bullets << "Amount you applied for: #{number_to_currency(payment.award_amount)}"

    if payment.student_loan_repayment&.nonzero?
      bullets << [
        "Student loan contribution: #{number_to_currency(payment.student_loan_repayment)}",
        "The Student Loans Company has told us that you’re currently repaying a student loan. This amount is deducted from your payment and goes towards repaying your loan."
      ].join("\n")
    end

    if payment.postgraduate_loan_repayment&.nonzero?
      bullets << [
        "Postgraduate Master’s or PhD loan contribution: #{number_to_currency(payment.postgraduate_loan_repayment)}",
        "The Student Loans Company has told us that you’re currently repaying a Postgraduate Master’s Loan or Postgraduate Doctoral Loan. This amount is deducted from your payment and goes towards repaying your loan."
      ].join("\n")
    end

    bullets << "Payment you receive: #{number_to_currency(payment.net_pay)}"
  end
end
