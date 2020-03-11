module StudentLoans
  # Used to display the information a claim checker needs to check to either
  # approve or reject a claim.
  class AdminTasksPresenter
    include Admin::PresenterMethods
    include ActionView::Helpers::NumberHelper

    attr_reader :claim

    def initialize(claim)
      @claim = claim
    end

    def qualifications
      [
        ["Award year", eligibility.qts_award_year_answer]
      ]
    end

    def employment
      [
        ["6 April 2018 to 5 April 2019", display_school(eligibility.claim_school)],
        [I18n.t("admin.current_school"), display_school(eligibility.current_school)]
      ]
    end

    def student_loan_amount
      [
        ["Student loan repayment amount", number_to_currency(eligibility.student_loan_repayment_amount)],
        ["Student loan plan", claim.student_loan_plan.humanize]
      ]
    end

    def identity_confirmation
      [
        ["Current school", eligibility.current_school.name],
        ["Contact number", eligibility.current_school.phone_number]
      ]
    end

    private

    def eligibility
      claim.eligibility
    end
  end
end
