module Journeys
  module FurtherEducationPayments
    # this class houses journey specific logic
    # when user comes back from one login callback
    # this class determines where we should send them
    class OneLoginRedirector
      attr_reader :journey_session

      def initialize(journey_session:)
        @journey_session = journey_session
      end

      def slug
        "sign-in"
      end
    end
  end
end
