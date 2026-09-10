module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class EligibilityChecker
      attr_reader :journey_session

      def initialize(journey_session:)
        @journey_session = journey_session
      end

      def ineligible?
        false
      end

      def ineligibility_reason
        nil
      end
    end
  end
end
