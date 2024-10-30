module Policies
  module EarlyYearsPayments
    class AdminTasksPresenter
      include Admin::PresenterMethods

      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end

      def employment
        [
          ["Current employment", claim.eligibility.eligible_ey_provider.nursery_name],
          ["Start date", l(claim.eligibility.start_date)]
        ]
      end

      def identity_confirmation
        []
      end

      def provider_entered_claimant_name
        claim.eligibility.practitioner_name
      end

      def one_login_claimant_name
        claim.onelogin_idv_full_name
      end

      def practitioner_journey_completed?
        claim.eligibility.practitioner_journey_completed?
      end

      def qualifications
        []
      end

      def student_loan_plan
        [
          ["Student loan plan", claim.student_loan_plan&.humanize]
        ]
      end
    end
  end
end
