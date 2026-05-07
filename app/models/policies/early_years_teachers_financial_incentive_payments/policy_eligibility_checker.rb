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
        if answers.teaching_qualification_confirmation == false
          :teaching_qualification_not_confirmed
        end
      end
    end
  end
end
