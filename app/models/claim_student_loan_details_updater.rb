class ClaimStudentLoanDetailsUpdater
  class StudentLoanUpdateError < StandardError; end

  def self.call(claim, admin)
    new(claim, admin).update_claim_with_latest_data
  end

  def initialize(claim, admin)
    @claim = claim
    @admin = admin
  end

  def update_claim_with_latest_data
    claim_changes = {}

    if claim.has_student_loan != student_loans_data.has_student_loan?
      claim_changes[:has_student_loan] = student_loans_data.has_student_loan?
    end

    if claim.student_loan_plan != student_loans_data.student_loan_plan
      claim_changes[:student_loan_plan] = student_loans_data.student_loan_plan
    end

    if student_loan_repayment_amount_changed?
      claim_changes[:eligibility_attributes] = {
        student_loan_repayment_amount: student_loans_data.total_repayment_amount
      }
    end

    amend_claim(claim_changes) if claim_changes.present?
  end

  private

  attr_reader :claim, :admin

  delegate :eligibility, to: :claim
  delegate :national_insurance_number, :date_of_birth, to: :claim

  def eligibility_student_loan_attributes
    {student_loan_repayment_amount: student_loans_data.total_repayment_amount}
  end

  def claim_student_loan_attributes
    {
      has_student_loan: student_loans_data.has_student_loan?,
      student_loan_plan: student_loans_data.student_loan_plan
    }
  end

  def student_loans_data
    @student_loans_data ||= StudentLoansDataPresenter.new(
      national_insurance_number: national_insurance_number,
      date_of_birth: date_of_birth
    )
  end

  def student_loan_repayment_amount_changed?
    return false unless claim.has_tslr_policy?

    claim.eligibility.student_loan_repayment_amount != student_loans_data.total_repayment_amount
  end

  def amend_claim(claim_changes)
    amendment = Amendment.amend_claim(
      claim,
      claim_changes,
      {
        notes: "Student loan details updated from SLC data",
        created_by: admin
      }
    )

    if amendment.errors.any?
      msg = [
        "Failed to update claim #{claim.id} student loan data.",
        "amendment_error: \"#{amendment.errors.full_messages.to_sentence}\"",
        "SLC data: #{claim_changes}"
      ].join(" ")

      raise StudentLoanUpdateError, msg
    end
  end
end
