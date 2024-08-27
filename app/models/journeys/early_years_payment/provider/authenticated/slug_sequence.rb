module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class SlugSequence
          CLAIM_SLUGS = %w[
            consent
            current-nursery
            paye-reference
            claimant-name
            start-date
            child-facing
            returner
            returner-worked-with-children
            employee-email
          ].freeze

          RESULTS_SLUGS = %w[
            check-your-answers
            ineligible
          ].freeze

          SLUGS = (CLAIM_SLUGS + RESULTS_SLUGS).freeze

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
            SLUGS.dup.tap do |sequence|
              if answers.first_job_within_6_months == false
                sequence.delete("returner-worked-with-children")
              end
            end
          end

          def magic_link?(slug)
            slug == MAGIC_LINK_SLUG
          end
        end
      end
    end
  end
end
