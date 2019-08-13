require "delegate"
require "csv"
require "excel_utils"

class TslrClaimCsvRow < SimpleDelegator
  def to_s
    CSV.generate_line(data)
  end

  private

  def data
    TslrClaimsCsv::FIELDS.map do |f|
      field = send(f)
      ExcelUtils.escape_formulas(field)
    end
  end

  def qts_award_year
    model.eligibility.qts_award_year
  end

  def claim_school_name
    model.eligibility.claim_school_name
  end

  def current_school_name
    model.eligibility.claim_school_name
  end

  def employment_status
    model.eligibility.employment_status.humanize
  end

  def date_of_birth
    model.date_of_birth.strftime("%d/%m/%Y")
  end

  def mostly_teaching_eligible_subjects
    model.eligibility.mostly_teaching_eligible_subjects? ? "Yes" : "No"
  end

  def student_loan_repayment_amount
    "£#{model.eligibility.student_loan_repayment_amount}"
  end

  def student_loan_repayment_plan
    model.student_loan_plan&.humanize
  end

  def submitted_at
    model.submitted_at.strftime("%d/%m/%Y %H:%M")
  end

  def model
    __getobj__
  end
end
