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
        end
      end
    end
  end
end
