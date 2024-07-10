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
        elsif answers.taught_at_least_one_term == false
          :must_teach_at_least_one_term
        elsif !answers.recent_further_education_teacher?
          :must_be_recent_further_education_teacher
        end
      end
    end
  end
end
