module Journeys
  module EarlyYearsPayment
    module Provider
      class SlugSequence
        SLUGS = %w[
          email-address
          check-your-email
          consent
          current-nursery
        ].freeze

        MAGIC_LINK_SLUG = "consent"

        def self.start_page_url
          Rails.application.routes.url_helpers.landing_page_path("early-years-payment-provider")
        end

        attr_reader :journey_session

        delegate :answers, to: :journey_session

        def initialize(journey_session)
          @journey_session = journey_session
        end

        def slugs
          SLUGS
        end

        def magic_link?(slug)
          slug == MAGIC_LINK_SLUG
        end
      end
    end
  end
end
