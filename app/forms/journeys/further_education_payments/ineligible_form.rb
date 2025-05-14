module Journeys
  module FurtherEducationPayments
    class IneligibleForm < Form
      def ineligibility_reason
        @ineligibility_reason ||= EligibilityChecker.new(journey_session:).ineligibility_reason
      end
    end
  end
end
