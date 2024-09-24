class Claim
  class ClaimsAwaitingDecisionFinder
    def initialize(policies:)
      @policies = policies
    end

    attr_reader :policies

    def claims_submitted_without_slc_data
      policies.map do |policy|
        journey_configuration = Journeys.for_policy(policy).configuration
        Claim
          .by_academic_year(journey_configuration.current_academic_year)
          .by_policy(policy)
          .awaiting_decision
          .where(submitted_using_slc_data: submitted_using_slc_data(policy))
      end.reduce(&:or)
    end

    private

    def submitted_using_slc_data(policy)
      if policy == Policies::FurtherEducationPayments
        # For 2024/2025 academic year onwards, only FE claims prior to the deployment of LUPEYALPHA-1010 have submitted_using_slc_data = nil
        [false, nil]
      else
        false
      end
    end
  end
end
