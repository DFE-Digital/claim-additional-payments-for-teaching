module Journeys
  module FurtherEducationPayments
    module Provider
      class SlugSequence
        SLUGS = [
          "sign-in",
          "verify-claim",
          "complete"
        ]

        def self.verify_claim_url(claim)
          Rails.application.routes.url_helpers.new_claim_path(
            module_parent::ROUTING_NAME,
            answers: {
              claim_id: claim.id
            }
          )
        end

        def self.start_page_url
          Rails.application.routes.url_helpers.landing_page_path(
            "further-education-payments-provider"
          )
        end

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
