class Claim
  class ClaimsAwaitingDecisionFinder
    def initialize(policies:)
      @policies = policies
    end

    attr_reader :policies

    def claims_submitted_without_slc_data
      policies.map do |policy|
        journey = Journeys.for_policy(policy)

        next if journey.nil? # ECP

        journey_configuration = journey.configuration
        Claim
          .by_academic_year(journey_configuration.current_academic_year)
          .by_policy(policy)
          .awaiting_decision
          .where(submitted_using_slc_data: [nil, false])
      end.compact.reduce(&:or)
    end
  end
end
