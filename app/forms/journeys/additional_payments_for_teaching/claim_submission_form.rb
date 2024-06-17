module Journeys
  module AdditionalPaymentsForTeaching
    class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
      def eligible_now_or_later
        eligibilities.select do |e|
          e.status == :eligible_now || e.status == :eligible_later
        end
      end

      private

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
        eligible_now_and_sorted.map do |e|
          {
            "policy" => e.policy.to_s,
            "award_amount" => BigDecimal(e.award_amount)
          }
        end
      end

      def eligible_now_and_sorted
        eligible_now.sort_by { |e| [-e.award_amount.to_i, e.policy.short_name] }
      end

      def eligible_now
        eligibilities.select { |e| e.status == :eligible_now }
      end
    end
  end
end
