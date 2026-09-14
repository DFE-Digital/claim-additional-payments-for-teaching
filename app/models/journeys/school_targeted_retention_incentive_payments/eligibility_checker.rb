module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class EligibilityChecker
      attr_reader :journey_session

      delegate_missing_to :answers

      def initialize(journey_session:)
        @journey_session = journey_session
      end

      def ineligible?
        ineligibility_reason.present?
      end

      def ineligibility_reason
        :school_ineligible if indicated_ineligible_school?
      end

      private

      def answers
        journey_session.answers
      end

      def indicated_ineligible_school?
        current_school.present? && !school_eligibility_class.new(current_school).eligible?
      end

      def school_eligibility_class
        Policies::TargetedRetentionIncentivePayments::SchoolEligibility
      end
    end
  end
end
