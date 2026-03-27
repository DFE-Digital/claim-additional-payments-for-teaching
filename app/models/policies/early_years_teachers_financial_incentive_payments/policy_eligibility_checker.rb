module Policies
  module EarlyYearsTeachersFinancialIncentivePayments
    class PolicyEligibilityChecker
      attr_reader :answers

      delegate_missing_to :answers

      def initialize(answers:)
        @answers = answers
      end

      def ineligible?
        false
      end
    end
  end
end
