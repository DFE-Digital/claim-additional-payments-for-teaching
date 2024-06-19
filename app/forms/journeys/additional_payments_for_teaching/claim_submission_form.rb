module Journeys
  module AdditionalPaymentsForTeaching
    class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
      def eligible_now_or_later
        eligibilities.select do |e|
          eligibility_checker.eligible_now_or_later.include?(e.policy)
        end
      end

      private

      def eligibility_checker
        @eligibility_checker ||= Journeys::EligibilityChecker.new(journey_session: journey_session)
      end

      def main_eligibility
        @main_eligibility ||= eligibilities.detect { |e| e.policy == main_policy }
      end

      def main_policy
        if answers.selected_claim_policy.present?
          answers.selected_claim_policy
        else
          Policies::EarlyCareerPayments
        end
      end

      def calculate_award_amount(eligibility)
        eligibility.award_amount = eligibility.policy::PolicyEligibilityChecker
          .new(answers: journey_session.answers)
          .calculate_award_amount
      end

      def generate_policy_options_provided
        eligibility_checker.policies_eligible_now_with_award_amount_and_sorted.map do |policy_with_award_amount|
          {
            "policy" => policy_with_award_amount.policy.to_s,
            "award_amount" => BigDecimal(policy_with_award_amount.award_amount)
          }
        end
      end
    end
  end
end
