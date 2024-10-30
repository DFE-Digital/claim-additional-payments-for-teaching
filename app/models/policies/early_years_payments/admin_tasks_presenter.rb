module Policies
  module EarlyYearsPayments
    class AdminTasksPresenter
      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end

      def identity_confirmation
        []
      end

      def provider_entered_claimant_name
        claim.eligibility.practitioner_entered_full_name
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
    end
  end
end
