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
      claim.assign_attributes(submitted_using_slc_data: found_data?) unless claim.submitted?

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
  delegate :repaying_plan_types, :total_repayment_amount, to: :student_loans_data

  alias_method :nino, :national_insurance_number

  def student_loans_data
    @student_loans_data ||= StudentLoansData.where(nino:, date_of_birth:)
  end

  def found_data?
    student_loans_data.any?
  end

  def eligibility_student_loan_attributes
    {student_loan_repayment_amount: total_repayment_amount}
  end

  def claim_student_loan_attributes
    {
      has_student_loan: found_data?,
      student_loan_plan: repaying_plan_types || Claim::NO_STUDENT_LOAN,
      # The following flags are irrelevant now, as it was used only to determine the plan type
      # TODO: remove the update when all the student loan questions and validations are removed from all journeys
      has_masters_doctoral_loan: false,
      postgraduate_masters_loan: false,
      postgraduate_doctoral_loan: false
    }
  end
end
