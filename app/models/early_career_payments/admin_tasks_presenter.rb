module EarlyCareerPayments
  # Used to display the information a claim checker needs to check to either
  # approve or reject a claim.
  class AdminTasksPresenter
    include Admin::PresenterMethods

    attr_reader :claim

    def initialize(claim)
      @claim = claim
    end

    def employment
      [
        [translate("admin.current_school"), display_school(eligibility.current_school)]
      ]
    end

    def identity_confirmation
      [
        ["Current school", eligibility.current_school.name],
        ["Contact number", eligibility.current_school.phone_number]
      ]
    end

    def qualifications
      [].tap do |a|
        a << [
          "ITT start/end year",
          I18n.t("answers.qts_award_years.on_date", year: eligibility.first_eligible_itt_academic_year.to_s(:long))
        ]

        a << [
          "ITT subject",
          eligibility.eligible_itt_subject.humanize
        ]
      end
    end

    private

    def eligibility
      claim.eligibility
    end
  end
end
