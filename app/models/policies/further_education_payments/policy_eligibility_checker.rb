module Policies
  module FurtherEducationPayments
    class PolicyEligibilityChecker
      attr_reader :answers

      delegate_missing_to :answers

      def initialize(answers:)
        @answers = answers
      end

      def status
        return :ineligible if ineligible?

        :eligible_now
      end

      def ineligible?
        ineligibility_reason.present?
      end

      def ineligibility_reason
        if answers.teaching_responsibilities == false
          :lack_teaching_responsibilities
        end
      end
    end
  end
end
