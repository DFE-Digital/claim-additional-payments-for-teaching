module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class IneligibleForm < Form
      def heading
        key = ineligibility_reason.presence || "generic"

        t(["heading", key])
      end

      def ineligibility_reason
        @ineligibility_reason ||= EligibilityChecker.new(
          journey_session: journey_session
        ).ineligibility_reason
      end
    end
  end
end
