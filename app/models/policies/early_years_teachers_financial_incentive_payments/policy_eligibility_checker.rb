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
        elsif answers.fifty_percent_time_as_eyt == false && answers.not_subject_to_performance_and_disciplinary == false
          :check_eligibility_both_not_confirmed
        elsif answers.fifty_percent_time_as_eyt == false
          :fifty_percent_time_as_eyt_not_confirmed
        elsif answers.not_subject_to_performance_and_disciplinary == false
          :not_subject_to_performance_and_disciplinary_not_confirmed
        elsif answers.has_eligible_qualification == false
          :teaching_qualification_ineligible
        elsif answers.claim_already_submitted_this_policy_year?
          :claim_already_submitted_this_policy_year
        end
      end
    end
  end
end
