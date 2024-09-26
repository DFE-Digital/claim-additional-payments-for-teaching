module Journeys
  module EarlyYearsPayment
    module Practitioner
      class SlugSequence
        SLUGS = %w[
          find-reference
          one-login-sign-in
          how-we-use-your-information
          personal-details
          enter-home-address
        ].freeze

        def self.start_page_url
          Rails.application.routes.url_helpers.landing_page_path("early-years-payment-practitioner")
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
