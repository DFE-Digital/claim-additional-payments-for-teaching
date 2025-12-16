# This checker is setup for prototyping.
# Once we start beta subclass `Journeys::EligibilityChecker` and implement
# actual eligibility logic.
module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class EligibilityChecker
        def initialize(journey_session:)
          @journey_session = journey_session
        end

        def ineligibility_reason
          nil
        end

        def ineligible?
          false
        end
      end
    end
  end
end
