module Policies
  module EarlyCareerPayments
    class PolicyEligibilityChecker
      include Eligible
      include EligibilityCheckable

      attr_reader :journey_session

      delegate :answers, to: :journey_session
      delegate_missing_to :answers

      def initialize(journey_session:)
        @journey_session = journey_session
      end
    end
  end
end
