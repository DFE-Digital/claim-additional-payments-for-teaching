module StudentLoans
  class AdminChecksPresenter
    include Admin::PresenterMethods

    attr_reader :eligibility

    def initialize(eligibility)
      @eligibility = eligibility
    end

    def qualifications
      [
        ["Award year", I18n.t("student_loans.questions.qts_award_years.#{eligibility.qts_award_year}")],
      ]
    end

    def employment
      [
        ["6 April 2018 to 5 April 2019", display_school(eligibility.claim_school)],
        [I18n.t("admin.current_school"), display_school(eligibility.current_school)],
      ]
    end
  end
end
