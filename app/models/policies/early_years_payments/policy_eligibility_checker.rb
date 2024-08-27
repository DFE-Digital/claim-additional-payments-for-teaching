module Policies
  module EarlyYearsPayments
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
        return false if answers.is_a?(Journeys::EarlyYearsPayment::Provider::Start::SessionAnswers)

        ineligibility_reason.present?
      end

      def ineligibility_reason
        if answers.nursery_urn.to_s == "none_of_the_above"
          :nursery_is_not_listed
        elsif ineligible_returner?
          :returner
        end
      end

      private

      def ineligible_returner?
        answers.returning_within_6_months && answers.returner_worked_with_children && answers.returner_contract_type == "permanent"
      end
    end
  end
end
