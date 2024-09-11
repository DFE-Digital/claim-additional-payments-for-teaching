class ClaimStudentLoanDetailsUpdater
  def self.call(claim)
    new(claim).update_claim_with_latest_data
  end

  def initialize(claim)
    @claim = claim
  end

  def update_claim_with_latest_data
    claim.transaction do
      if claim.has_tslr_policy?
        eligibility.update!(eligibility_student_loan_attributes)
        claim.assign_attributes(claim_student_loans_policy_student_loan_attributes)
      else
        claim.assign_attributes(claim_student_loan_attributes)
      end

      claim.save!(context: :"student-loan")
    end
  rescue => e
    # If something goes wrong, log the error and continue
    Rollbar.error(e)
  end

  private

  attr_reader :claim

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

  def claim_student_loans_policy_student_loan_attributes
    {
      has_student_loan: student_loans_data.has_student_loan_for_student_loan_policy,
      student_loan_plan: student_loans_data.student_loan_plan_for_student_loan_policy
    }
  end

  def student_loans_data
    @student_loans_data ||= StudentLoansDataPresenter.new(
      national_insurance_number: national_insurance_number,
      date_of_birth: date_of_birth
    )
  end
end
