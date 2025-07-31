module Journeys
  module EarlyYearsPayment
    module Practitioner
      # this class houses journey specific logic
      # when user comes back from one login callback
      # this class determines where we should send them
      class OneLoginRedirector
        attr_reader :journey_session

        def initialize(journey_session:)
          @journey_session = journey_session
        end

        def auth_slug
          "sign-in"
        end

        def idv_slug
          "sign-in"
        end
      end
    end
  end
end
