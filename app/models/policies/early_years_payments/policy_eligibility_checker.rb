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
        start_ineligibility_reason || provider_ineligibility_reason || practitioner_ineligibility_reason
      end

      def start_ineligibility_reason
        return nil unless answers.is_a?(Journeys::EarlyYearsPayment::Provider::Start::SessionAnswers)

        if !EligibleEyProvider.eligible_email?(answers.email_address)
          :email_not_on_whitelist
        end
      end

      def provider_ineligibility_reason
        return nil unless answers.is_a?(Journeys::EarlyYearsPayment::Provider::Authenticated::SessionAnswers)

        if answers.nursery_urn.to_s == "none_of_the_above"
          :nursery_is_not_listed
        elsif answers.child_facing_confirmation_given == false
          :not_child_facing_enough
        elsif ineligible_returner?
          :returner
        end
      end

      def practitioner_ineligibility_reason
        return nil unless answers.is_a?(Journeys::EarlyYearsPayment::Practitioner::SessionAnswers)

        if answers.reference_number_found == false
          :reference_number_not_found
        elsif answers.claim_already_submitted == true
          :claim_already_submitted
        end
      end

      private

      def ineligible_returner?
        answers.returning_within_6_months && answers.returner_worked_with_children && answers.returner_contract_type == "permanent"
      end
    end
  end
end
