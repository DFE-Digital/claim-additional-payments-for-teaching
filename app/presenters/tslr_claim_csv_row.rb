require "delegate"
require "csv"

class TslrClaimCsvRow < SimpleDelegator
  def data
    [
      reference,
      qts_award_year,
      claim_school_name,
      employment_status.humanize,
      current_school_name,
      full_name,
      address_line_1,
      address_line_2,
      address_line_3,
      address_line_4,
      postcode,
      date_of_birth,
      teacher_reference_number,
      national_insurance_number,
      email_address,
      mostly_teaching_eligible_subjects,
      bank_sort_code,
      bank_account_number,
      student_loan_repayment_amount,
    ]
  end

  private

  def date_of_birth
    model.date_of_birth.strftime("%d/%m/%Y")
  end

  def mostly_teaching_eligible_subjects
    model.mostly_teaching_eligible_subjects? ? "Yes" : "No"
  end

  def student_loan_repayment_amount
    "£#{model.student_loan_repayment_amount}"
  end

  def model
    __getobj__
  end
end
