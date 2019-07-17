require "delegate"
require "csv"

class TslrClaimCsvRow < SimpleDelegator
  include ActiveSupport::NumberHelper

  def to_s
    CSV.generate_line(data)
  end

  private

  def data
    TslrClaimsCsv::FIELDS.map { |f| send(f) }
  end

  def employment_status
    model.employment_status.humanize
  end

  def date_of_birth
    model.date_of_birth.strftime("%d/%m/%Y")
  end

  def mostly_teaching_eligible_subjects
    model.mostly_teaching_eligible_subjects? ? "Yes" : "No"
  end

  def student_loan_repayment_amount
    number_to_currency(model.student_loan_repayment_amount)
  end

  def submitted_at
    model.submitted_at.strftime("%d/%m/%Y %H:%M")
  end

  def model
    __getobj__
  end
end
