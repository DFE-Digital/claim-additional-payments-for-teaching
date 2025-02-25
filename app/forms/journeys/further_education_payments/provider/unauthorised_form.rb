# Required to get page sequence to think this is a "normal" journey
module Journeys
  module FurtherEducationPayments
    module Provider
      class UnauthorisedForm < Form
        def initialize(journey_session)
          @journey_session = journey_session
        end

        def valid?
          true
        end

        def invalid?
          false
        end

        def clear_answers_from_session
        end

        def completed?
          true
        end
      end
    end
  end
end
