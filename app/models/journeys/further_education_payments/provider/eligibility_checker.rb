# Required to get page sequence to think this is a "normal" journey
module Journeys
  module FurtherEducationPayments
    module Provider
      class EligibilityChecker < Journeys::EligibilityChecker
        def ineligible?
          false
        end
      end
    end
  end
end
