module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        class EligibilityChecker
          def initialize(journey_session:)
          end

          def ineligible?
            false
          end
        end
      end
    end
  end
end
