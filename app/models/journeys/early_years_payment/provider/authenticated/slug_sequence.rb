module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class SlugSequence
          SLUGS = %w[
            consent
            current-nursery
            paye-reference
            claimant-name
            start-date
            child-facing
            returner
            ineligible
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
end
