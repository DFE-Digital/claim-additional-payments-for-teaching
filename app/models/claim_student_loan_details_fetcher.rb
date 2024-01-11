class ClaimStudentLoanDetailsFetcher
  def self.call(claim)
    new(claim).fetch_latest_data
  end

  def initialize(claim)
    @claim = claim
  end

  def fetch_latest_data
    {student_loan_repayment_amount:}
  end

  private

  attr_reader :claim

  delegate :national_insurance_number, :date_of_birth, to: :claim
  delegate :total_repayment_amount, to: :student_loans_data

  alias_method :nino, :national_insurance_number

  def student_loans_data
    @student_loans_data ||= StudentLoansData.where(nino:, date_of_birth:)
  end

  def student_loan_repayment_amount
    student_loans_data.any? ? total_repayment_amount : nil
  end
end
