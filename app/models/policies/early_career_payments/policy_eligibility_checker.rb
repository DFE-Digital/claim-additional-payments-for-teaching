module Policies
  module EarlyCareerPayments
    class PolicyEligibilityChecker
      include Eligible
      include EligibilityCheckable

      attr_reader :answers

      delegate_missing_to :answers

      def initialize(answers:)
        @answers = answers
      end
    end
  end
end
