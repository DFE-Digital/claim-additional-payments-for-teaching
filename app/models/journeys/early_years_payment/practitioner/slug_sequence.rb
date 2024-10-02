module Journeys
  module EarlyYearsPayment
    module Practitioner
      class SlugSequence
        SLUGS = %w[
          find-reference
          sign-in
          how-we-use-your-information
          personal-details
          enter-home-address
          email-address
          email-verification
          provide-mobile-number
          bank-or-building-society
          check-your-answers
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
