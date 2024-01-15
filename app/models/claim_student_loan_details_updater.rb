class ClaimStudentLoanDetailsUpdater
  def self.call(claim)
    new(claim).update_claim_with_latest_data
  end

  def initialize(claim)
    @claim = claim
  end

  def update_claim_with_latest_data
    with_reload_on_failure do
      claim.transaction do
        eligibility.update(student_loan_repayment_amount: total_repayment_amount)
        claim.update(has_student_loan: found_data?, student_loan_plan: repaying_plan_types || Claim::NO_STUDENT_LOAN)
        # The following flags are irrelevant now, as we don't need to differentiate between student loan types
        # TODO: remove the update when all the student loan questions and validations are removed from all journeys
        claim.update(has_masters_doctoral_loan: false, postgraduate_masters_loan: false, postgraduate_doctoral_loan: false)
      end
    end
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

  def with_reload_on_failure
    return unless block_given?

    yield || (claim.reload && false)
  end
end
