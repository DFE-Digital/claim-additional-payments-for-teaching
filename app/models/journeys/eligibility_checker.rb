module Journeys
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

    def eligible_now
      policies.select { |policy| policy::PolicyEligibilityChecker.new(answers: @journey_session.answers).status == :eligible_now }
    end

    def eligible_later
      policies.select { |policy| policy::PolicyEligibilityChecker.new(answers: @journey_session.answers).status == :eligible_later }
    end

    def single_choice_only?
      policies_eligible_now.one?
    end

    def policies_eligible_now
      policies.select { |policy| policy::PolicyEligibilityChecker.new(journey_session: @journey_session.answers).status == :eligible_now }
    end

    def policies_eligible_now_and_sorted
      policies_eligible_now.sort_by { |policy|
        [-policy::PolicyEligibilityChecker.new(answers: @journey_session.answers).calculate_award_amount, policy.short_name]
      }
    end

    private

    def policies
      Journeys.for_routing_name(journey_session.journey)::POLICIES
    end

    def anything_eligible_now?
      eligible_now.any?
    end

    def anything_eligible_later?
      eligible_later.any?
    end

    # NOTE: not to be confused with `ineligible?`
    # e.g. having `eligible_later` is considered ineligible but not an overall status of :ineligible
    def everything_ineligible?
      policies.all? { |policy| policy::PolicyEligibilityChecker.new(answers: @journey_session.answers).status == :ineligible }
    end
  end
end
