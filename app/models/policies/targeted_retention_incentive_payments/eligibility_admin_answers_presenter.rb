module Policies
  module TargetedRetentionIncentivePayments
    class EligibilityAdminAnswersPresenter
      include Admin::PresenterMethods

      attr_reader :eligibility

      def initialize(eligibility)
        @eligibility = eligibility
      end

      # Formats the eligibility as a list of questions and answers.
      # Suitable for playback to the service operators for them to review
      # the claim.
      #
      # Returns an array. Each element of this an array is an array of two
      # elements:
      # [0]: short question text;
      # [1]: answer text;
      def answers
        [].tap do |a|
          a << nqt_in_academic_year_after_itt
          a << employed_as_supply_teacher
          a << degree_in_an_eligible_subject
        end
      end

      private

      def nqt_in_academic_year_after_itt
        [
          translate("targeted_retention_incentive_payments.admin.nqt_in_academic_year_after_itt"),
          (eligibility.nqt_in_academic_year_after_itt? ? "Yes" : "No")
        ]
      end

      def employed_as_supply_teacher
        [
          translate("targeted_retention_incentive_payments.admin.employed_as_supply_teacher"),
          (eligibility.employed_as_supply_teacher? ? "Yes" : "No")
        ]
      end

      def degree_in_an_eligible_subject
        [
          translate("targeted_retention_incentive_payments.admin.degree_in_an_eligible_subject"),
          display_boolean(eligibility.eligible_degree_subject)
        ]
      end
    end
  end
end
