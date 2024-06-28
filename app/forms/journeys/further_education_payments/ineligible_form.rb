module Journeys
  module FurtherEducationPayments
    class IneligibleForm < Form
      def journey_eligibility_checker
        @journey_eligibility_checker ||= EligibilityChecker.new(journey_session:)
      end
    end
  end
end
