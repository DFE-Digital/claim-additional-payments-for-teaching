module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class SlugSequence
          CLAIM_SLUGS = %w[
            expired-link
            consent
            current-nursery
            paye-reference
            claimant-name
            start-date
            child-facing
            returner
            returner-worked-with-children
            returner-contract-type
            employee-email
          ].freeze

          RESULTS_SLUGS = %w[
            check-your-answers
            confirmation
            ineligible
          ].freeze

          SLUGS = (CLAIM_SLUGS + RESULTS_SLUGS).freeze

          RESTRICTED_SLUGS = [].freeze

          DEAD_END_SLUGS = %w[
            expired-link
            ineligible
          ]

          MAGIC_LINK_SLUG = "consent"

          def self.start_page_url
            Rails.application.routes.url_helpers.landing_page_path("early-years-payment")
          end

          attr_reader :journey_session

          delegate :answers, to: :journey_session

          def initialize(journey_session)
            @journey_session = journey_session
          end

          def slugs
            if answers.invalid_magic_link
              return ["expired-link"]
            end

            SLUGS.dup.tap do |sequence|
              sequence.delete("expired-link")

              if !answers.returning_within_6_months
                sequence.delete("returner-worked-with-children")
                sequence.delete("returner-contract-type")
              end

              if !answers.returner_worked_with_children
                sequence.delete("returner-contract-type")
              end
            end
          end

          def magic_link?(slug)
            slug == MAGIC_LINK_SLUG
          end

          def journey
            Journeys::EarlyYearsPayment::Provider::Authenticated
          end
        end
      end
    end
  end
end
