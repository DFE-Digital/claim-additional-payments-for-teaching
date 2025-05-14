module Journeys
  class EligibilityChecker
    attr_reader :journey_session

    def initialize(journey_session:)
      @journey_session = journey_session
    end

    def ineligibility_reason
      policies.map do |policy|
        policy::PolicyEligibilityChecker.new(
          answers: @journey_session.answers
        ).ineligibility_reason
      end.compact.first
    end

    def ineligible?
      policies.all? { |policy| policy::PolicyEligibilityChecker.new(answers: @journey_session.answers).ineligible? }
    end

    private

    def policies
      Journeys.for_routing_name(journey_session.journey).policies
    end
  end
end
