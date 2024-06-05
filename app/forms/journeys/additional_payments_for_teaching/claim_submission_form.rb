module Journeys
  module AdditionalPaymentsForTeaching
    class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
      private

      def selected_claim_policy
        case answers.selected_policy
        when "EarlyCareerPayments"
          Policies::EarlyCareerPayments
        when "LevellingUpPremiumPayments"
          Policies::LevellingUpPremiumPayments
        when nil
          nil
        else
          fail "Invalid policy selected: #{answers.selected_policy}"
        end
      end

      def main_eligibility
        @main_eligibility ||= eligibilities.detect { |e| e.policy == main_policy }
      end

      def main_policy
        if selected_claim_policy.present?
          selected_claim_policy
        else
          Policies::EarlyCareerPayments
        end
      end

      def eligibility_checker
        main_policy::EligibilityChecker.new(answers)
      end

      def calculate_award_amount(eligibility)
        eligibility.award_amount = eligibility_checker.calculate_award_amount
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
        eligibility_checkers { |e| e.status == :eligible_now }
      end

      def eligibility_checkers
        @eligibility_checkers ||= AdditionalPaymentsForTeaching.eligibility_checkers(answers)
      end
    end
  end
end
