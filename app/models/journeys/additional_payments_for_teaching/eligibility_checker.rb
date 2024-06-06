module Journeys
  module AdditionalPaymentsForTeaching
    class EligibilityChecker
      attr_reader :journey_session

      def initialize(journey_session:)
        @journey_session = journey_session
      end

      def status
        if anything_eligible_now?
          :eligible_now
        elsif anything_eligible_later?
          :eligible_later
        elsif everything_ineligible?
          :ineligible
        else
          :undetermined
        end
      end

      def ineligible?
        everything_ineligible?
      end

      private

      def policies
        Journeys.for_routing_name(journey_session.journey)::POLICIES
      end

      def anything_eligible_now?
        policies.any? { |policy| policy::PolicyEligibilityChecker.new(journey_session: @journey_session).status == :eligible_now }
      end

      def anything_eligible_later?
        policies.any? { |policy| policy::PolicyEligibilityChecker.new(journey_session: @journey_session).status == :eligible_later }
      end

      def everything_ineligible?
        policies.all? { |policy| policy::PolicyEligibilityChecker.new(journey_session: @journey_session).status == :ineligible }
      end

      def anything_ineligible?
        policies.any? { |policy| policy::PolicyEligibilityChecker.new(journey_session: @journey_session).status == :ineligible }
      end
    end
  end
end
