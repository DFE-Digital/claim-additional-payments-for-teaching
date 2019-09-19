require "delegate"
require "csv"
require "excel_utils"

module StudentLoans
  class ClaimCsvRow < SimpleDelegator
    def to_s
      CSV.generate_line(data)
    end

    private

    def data
      StudentLoans::ClaimsCsv::FIELDS.map do |f|
        field = send(f)
        ExcelUtils.escape_formulas(field)
      end
    end

    def qts_award_year
      model.eligibility.qts_award_year
    end

    def claim_school_name
      model.eligibility.selected_employment.school_name
    end

    def current_school_name
      model.eligibility.current_school_name
    end

    def employment_status
      model.eligibility.employment_status.humanize
    end

    def date_of_birth
      model.date_of_birth.strftime("%d/%m/%Y")
    end

    def had_leadership_position
      model.eligibility.had_leadership_position? ? "Yes" : "No"
    end

    def mostly_performed_leadership_duties
      model.eligibility.mostly_performed_leadership_duties? ? "Yes" : "No"
    end

    def student_loan_repayment_amount
      "£#{model.eligibility.selected_employment.student_loan_repayment_amount}"
    end

    def student_loan_repayment_plan
      model.student_loan_plan&.humanize
    end

    def biology_taught
      model.eligibility.selected_employment.biology_taught? ? "Yes" : "No"
    end

    def chemistry_taught
      model.eligibility.selected_employment.chemistry_taught? ? "Yes" : "No"
    end

    def computer_science_taught
      model.eligibility.selected_employment.computer_science_taught? ? "Yes" : "No"
    end

    def languages_taught
      model.eligibility.selected_employment.languages_taught? ? "Yes" : "No"
    end

    def physics_taught
      model.eligibility.selected_employment.physics_taught? ? "Yes" : "No"
    end

    def submitted_at
      model.submitted_at.strftime("%d/%m/%Y %H:%M")
    end

    def model
      __getobj__
    end
  end
end
