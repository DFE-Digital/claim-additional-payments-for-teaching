module Journeys
  module EarlyYearsPayment
    module Provider
      module Start
        class SlugSequence
          SLUGS = %w[
            email-address
            check-your-email
            expired-link
            ineligible
          ].freeze

          def self.start_page_url
            Rails.application.routes.url_helpers.landing_page_path("early-years-payment")
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
end
