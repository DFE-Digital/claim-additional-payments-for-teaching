module Journeys
  module FurtherEducationPayments
    class EligibilityChecker < Journeys::EligibilityChecker
      def ineligible?
        false
      end
    end
  end
end
