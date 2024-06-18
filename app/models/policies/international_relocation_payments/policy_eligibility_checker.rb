module Policies
  module InternationalRelocationPayments
    class PolicyEligibilityChecker
      attr_reader :answers

      delegate_missing_to :answers

      def initialize(answers:)
        @answers = answers
      end

      def status
        :eligible_now
      end

      def ineligible?
        false
      end
    end
  end
end
