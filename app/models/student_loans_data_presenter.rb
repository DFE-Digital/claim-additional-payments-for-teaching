class StudentLoansDataPresenter
  def initialize(national_insurance_number:, date_of_birth:)
    @national_insurance_number = national_insurance_number
    @date_of_birth = date_of_birth
  end

  def found_data?
    student_loans_data.any?
  end

  def has_student_loan?
    return unless found_data?

    student_loans_data.repaying_plan_types.present?
  end

  def student_loan_plan
    return nil if student_loans_data.repaying_plan_types.nil? && !found_data?

    student_loans_data.repaying_plan_types || Claim::NO_STUDENT_LOAN
  end

  def total_repayment_amount
    student_loans_data.total_repayment_amount
  end

  private

  attr_reader :national_insurance_number, :date_of_birth

  def student_loans_data
    @student_loans_data ||= StudentLoansData.where(
      nino: national_insurance_number,
      date_of_birth: date_of_birth
    )
  end
end
