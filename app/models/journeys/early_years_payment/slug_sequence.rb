module Journeys
  module EarlyYearsPayment
    class SlugSequence
      ELIGIBILITY_SLUGS = %w[].freeze

      PERSONAL_DETAILS_SLUGS = %w[].freeze

      PAYMENT_DETAILS_SLUGS = %w[].freeze

      RESULTS_SLUGS = %w[].freeze

      SLUGS = (
        ELIGIBILITY_SLUGS +
        PERSONAL_DETAILS_SLUGS +
        PAYMENT_DETAILS_SLUGS +
        RESULTS_SLUGS
      ).freeze

      def self.start_page_url
        if Rails.env.production?
          "https://www.example.com" # TODO: update to correct guidance
        else
          Rails.application.routes.url_helpers.landing_page_path("early-years-payment")
        end
      end

      attr_reader :journey_session

      delegate :answers, to: :journey_session

      def initialize(journey_session)
        @journey_session = journey_session
      end

      def slugs
        SLUGS
      end
    end
  end
end
