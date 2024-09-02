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
        ineligibility_reason.present?
      end

      def ineligibility_reason
        start_ineligibility_reason || authenticated_ineligibility_reason
      end

      def start_ineligibility_reason
        return nil unless answers.is_a?(Journeys::EarlyYearsPayment::Provider::Start::SessionAnswers)

        if !EligibleEyProvider.eligible_email?(answers.email_address)
          :email_not_on_whitelist
        end
      end

      def authenticated_ineligibility_reason
        return nil unless answers.is_a?(Journeys::EarlyYearsPayment::Provider::Authenticated::SessionAnswers)

        if answers.nursery_urn.to_s == "none_of_the_above"
          :nursery_is_not_listed
        elsif answers.child_facing_confirmation_given == false
          :not_child_facing_enough
        end
      end
    end
  end
end
