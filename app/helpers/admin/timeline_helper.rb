module Admin
  module TimelineHelper
    def admin_amendment_details(amendment)
      amendment.claim_changes.map { |attribute, changes|
        admin_change_details(attribute, changes)
      }.sort_by(&:first)
    end

    private

    def admin_change_details(attribute, changes)
      result = [admin_amendment_attribute_name(attribute)]

      if changes
        result += [
          admin_amendment_format_attribute(attribute, changes[0]),
          admin_amendment_format_attribute(attribute, changes[1])
        ]
      end

      result
    end

    def admin_amendment_attribute_name(attribute)
      override = case attribute.to_s
                 when "student_loan_plan" then t("student_loans.admin.student_loan_repayment_plan")
      end

      override || attribute.to_s.humanize
    end

    def admin_amendment_format_attribute(attribute, value)
      override = case attribute.to_s
                 when "payroll_gender" then "don’t know" if value.to_s == "dont_know"
                 when "date_of_birth" then l(value, format: :day_month_year)
                 when "student_loan_plan" then value.to_s == "not_applicable" ? "not applicable" : value&.humanize
      end

      override || value.to_s
    end
  end
end
