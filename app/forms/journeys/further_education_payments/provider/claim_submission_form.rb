# Required to get page sequence to think this is a "normal" journey
module Journeys
  module FurtherEducationPayments
    module Provider
      class ClaimSubmissionForm
        def initialize(journey_session)
          @journey_session = journey_session
        end

        # We don't want page sequence to redirect us
        def valid?
          false
        end
      end
    end
  end
end
