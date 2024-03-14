module Policies
  module EarlyCareerPayments
    # Used to display the information a claim checker needs to check to either
    # approve or reject a claim.
    class AdminTasksPresenter < BaseAdminTasksPresenter
      include Admin::PresenterMethods

      def employment
        [
          [translate("admin.current_school"), display_school(eligibility.current_school)]
        ]
      end

      def qualifications
        [].tap do |a|
          a << [
            "Qualification",
            I18n.t("early_career_payments.answers.qualification.#{eligibility.qualification}")
          ]

          year_type = eligibility.postgraduate_itt? ? "start" : "end"

          a << [
            "ITT #{year_type} year",
            I18n.t("answers.qts_award_years.on_date", year: eligibility.itt_academic_year.to_s(:long))
          ]

          a << [
            "ITT subject",
            I18n.t("early_career_payments.answers.eligible_itt_subject.#{eligibility.eligible_itt_subject}")
          ]
        end
      end

      def census_subjects_taught
        [
          ["Subject", eligibility.eligible_itt_subject.titleize]
        ]
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
    end
  end
end
