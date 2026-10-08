module Policies
  module EarlyYearsTeachersFinancialIncentivePayments
    class PolicyEligibilityChecker
      attr_reader :answers

      delegate_missing_to :answers

      def initialize(answers:)
        @answers = answers
      end

      def ineligible?
        ineligibility_reason.present?
      end

      def ineligibility_reason
        if answers.nursery&.ineligible?
          :ineligible_provider
        elsif answers.teaching_qualification_confirmation == false
          :teaching_qualification_not_confirmed
        elsif answers.meets_teaching_standards == false
          :check_eligibility_not_confirmed
        elsif answers.has_eligible_qualification == false
          :teaching_qualification_ineligible
        elsif answers.claim_already_submitted_this_policy_year?
          :claim_already_submitted_this_policy_year
        end
      end
    end
  end
end
