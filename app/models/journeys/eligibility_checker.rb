module Journeys
  class EligibilityChecker
    attr_reader :journey_session

    PolicyWithAwardAmount = Struct.new(:policy, :award_amount)

    def initialize(journey_session:)
      @journey_session = journey_session
    end

    def status
      if anything_eligible_now?
        :eligible_now
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

    # FIXME: duplication of #policies_eligible_now
    def eligible_now
      policies.select { |policy| policy::PolicyEligibilityChecker.new(answers: @journey_session.answers).status == :eligible_now }
    end

    def single_choice_only?
      policies_eligible_now.one?
    end

    def policies_eligible_now
      policies.select { |policy| policy::PolicyEligibilityChecker.new(answers: @journey_session.answers).status == :eligible_now }
    end

    def policies_eligible_now_with_award_amount_and_sorted
      policies_eligible_now_with_award_amount.sort_by { |policy_with_award_amount|
        [-policy_with_award_amount.award_amount, policy_with_award_amount.policy.short_name]
      }
    end

    def policies_eligible_now_and_sorted
      policies_eligible_now_with_award_amount_and_sorted.map { |policy_with_award_amount| policy_with_award_amount.policy }
    end

    def potentially_still_eligible
      policies.select do |policy|
        policy::PolicyEligibilityChecker.new(
          answers: @journey_session.answers
        ).status != :ineligible
      end
    end

    private

    def policies_eligible_now_with_award_amount
      policies_eligible_now.map { |policy|
        PolicyWithAwardAmount.new(policy, policy::PolicyEligibilityChecker.new(answers: @journey_session.answers).calculate_award_amount)
      }
    end

    def policies
      Journeys.for_routing_name(journey_session.journey).policies
    end

    def anything_eligible_now?
      eligible_now.any?
    end

    # NOTE: not to be confused with `ineligible?`
    def everything_ineligible?
      policies.all? { |policy| policy::PolicyEligibilityChecker.new(answers: @journey_session.answers).status == :ineligible }
    end
  end
end
