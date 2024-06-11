class ClaimStudentLoanDetailsUpdater
  def self.call(claim)
    new(claim).update_claim_with_latest_data
  end

  def initialize(claim)
    @claim = claim
  end

  def update_claim_with_latest_data
    claim.transaction do
      eligibility.update!(eligibility_student_loan_attributes) if claim.has_tslr_policy?

      # When the claim hasn't been submitted yet, we need a way of knowing if the student loan
      # details on the claim were found using the SLC data we held before submission;
      # after submission, the `submitted_using_slc_data` value must not change
      claim.assign_attributes(submitted_using_slc_data: student_loans_data.found_data?) unless claim.submitted?

      claim.assign_attributes(claim_student_loan_attributes)
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
      has_student_loan: student_loans_data.found_data?,
      student_loan_plan: student_loans_data.student_loan_plan
    }
  end

  def student_loans_data
    @student_loans_data ||= StudentLoansDataPresenter.new(
      national_insurance_number: national_insurance_number,
      date_of_birth: date_of_birth
    )
  end
end
