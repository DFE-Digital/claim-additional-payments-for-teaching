module StudentLoans
  # Used to display the information a claim checker needs to check to either
  # approve or reject a claim.
  class AdminTasksPresenter < BaseAdminTasksPresenter
    include StudentLoans::PresenterMethods
    include Admin::PresenterMethods
    include ActionView::Helpers::NumberHelper

    def employment
      [
        [financial_year_for_academic_year(claim.academic_year), display_school(eligibility.claim_school)],
        [translate("admin.current_school"), display_school(eligibility.current_school)]
      ]
    end

    def qualifications
      [
        ["Award year", qts_award_year_answer(eligibility)]
      ]
    end


    def student_loan_amount
      [
        ["Student loan repayment amount", number_to_currency(eligibility.student_loan_repayment_amount)],
        ["Student loan plan", claim.student_loan_plan.humanize]
      ]
    end

    def census_subjects_taught
      [
        ["Subjects taught", subject_list(eligibility.subjects_taught)]
      ]
    end

    private

    def financial_year_for_academic_year(academic_year)
      end_year = academic_year.start_year
      start_year = end_year - 1

      "6 April #{start_year} to 5 April #{end_year}"
    end
  end
end
