module Journeys
  module TargetedRetentionIncentivePayments
    class IneligibleForm < Form
      def heading
        if ineligibility_reason == :school_ineligible
          t(["heading", "current_school"])
        else
          t(["heading", "generic"])
        end
      end

      def ineligibility_reason
        @ineligibility_reason ||= EligibilityChecker.new(
          journey_session: journey_session
        ).ineligibility_reason
      end
    end
  end
end
