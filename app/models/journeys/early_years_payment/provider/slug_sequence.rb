module Journeys
  module EarlyYearsPayment
    module Provider
      class SlugSequence
        SLUGS = %w[].freeze

        def self.start_page_url
          if Rails.env.production?
            "https://www.example.com" # TODO: update to correct guidance
          else
            Rails.application.routes.url_helpers.landing_page_path("early-years-payment-provider")
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
end
