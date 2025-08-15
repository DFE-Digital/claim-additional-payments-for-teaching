module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        class SlugSequence
          SLUGS = %w[
            claimant-employed-by-nursery
            claimant-personal-details
            claimant-not-employed-by-nursery
            check-answers
            confirmation
            ineligible

          ]

          RESTRICTED_SLUGS = []
          DEAD_END_SLUGS = %w[
            claimant-not-employed-by-nursery
            ineligible
          ]

          def self.start_page_url
            Rails.application.routes.url_helpers.landing_page_path(
              "early-years-payment-provider-alternative-idv"
            )
          end

          attr_reader :journey_session

          delegate :answers, to: :journey_session

          def initialize(journey_session)
            @journey_session = journey_session
          end

          def slugs
            array = []

            if answers.claimant_employed_by_nursery == false
              return ["claimant-not-employed-by-nursery"]
            end

            array << "claimant-employed-by-nursery"
            array << "claimant-personal-details"
            array << "check-answers"
            array << "confirmation"

            array
          end

          def journey
            Journeys::EarlyYearsPayment::Provider::AlternativeIdv
          end
        end
      end
    end
  end
end
