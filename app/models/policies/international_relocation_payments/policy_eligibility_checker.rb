module Policies
  module InternationalRelocationPayments
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
        ineligible_reason.present?
      end

      private

      def ineligible_reason
        case answers.attributes.symbolize_keys
        in application_route: "other"
          "application route other not accecpted"
        in state_funded_secondary_school: false
          "school not state funded"
        else
          nil
        end
      end
    end
  end
end
