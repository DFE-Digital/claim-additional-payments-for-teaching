module StudentLoans
  # Used to display the information a claim checker needs to check to either
  # approve or reject a claim
  #
  # Note this presenter is only intented for use with eligible claims and
  # therefor makes certain assumptions about the claim and eligibility.
  # Specifically it assumes the QTS question was answered with
  # :on_or_after_cut_off_date.
  class AdminChecksPresenter
    include Admin::PresenterMethods

    attr_reader :claim

    def initialize(claim)
      @claim = claim
    end

    def qualifications
      [
        ["Award year", qts_award_year_answer],
      ]
    end

    def employment
      [
        ["6 April 2018 to 5 April 2019", display_school(eligibility.claim_school)],
        [I18n.t("admin.current_school"), display_school(eligibility.current_school)],
      ]
    end

    private

    def eligibility
      claim.eligibility
    end

    def qts_award_year_answer
      qts_cut_off_for_claim = StudentLoans.first_eligible_qts_award_year(claim.academic_year)
      I18n.t("answers.qts_award_years.on_or_after_cut_off_date", year: qts_cut_off_for_claim.to_s(:long))
    end
  end
end
