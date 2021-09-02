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
          "Qualification",
          I18n.t("early_career_payments.answers.qualification.#{eligibility.qualification}")
        ]

        a << [
          "ITT start/end year",
          I18n.t("answers.qts_award_years.on_date", year: AcademicYear.new(2018).to_s(:long))
        ]

        a << [
          "ITT subject",
          I18n.t("early_career_payments.answers.eligible_itt_subject.mathematics")
        ]
      end
    end

    private

    def eligibility
      claim.eligibility
    end
  end
end
