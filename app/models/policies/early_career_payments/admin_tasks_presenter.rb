module Policies
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
          ["Current school", eligibility.current_school&.name],
          ["Contact number", eligibility.current_school&.phone_number]
        ]
      end

      def census_subjects_taught
        [
          ["Subject", eligibility.eligible_itt_subject&.titleize]
        ]
      end

      def qualifications
        [].tap do |a|
          a << [
            "Qualification",
            I18n.t("early_career_payments.forms.qualification.answers.#{eligibility.qualification}")
          ]

          year_type = eligibility.postgraduate_itt? ? "start" : "end"

          a << [
            "ITT #{year_type} year",
            I18n.t("answers.qts_award_years.on_date", year: eligibility.itt_academic_year.to_s(:long))
          ]

          a << [
            "ITT subject",
            I18n.t("early_career_payments.forms.eligible_itt_subject.answers.#{eligibility.eligible_itt_subject}")
          ]
        end
      end

      def induction_confirmation
        year_type = eligibility.postgraduate_itt? ? "start" : "end"

        [
          [
            "ITT #{year_type} year",
            I18n.t("answers.qts_award_years.on_date", year: eligibility.itt_academic_year.to_s(:long))
          ]
        ]
      end

      def student_loan_plan
        [
          ["Student loan plan", claim.student_loan_plan&.humanize]
        ]
      end

      private

      def eligibility
        claim.eligibility
      end
    end
  end
end
