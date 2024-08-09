module Journeys
  module FurtherEducationPayments
    module Provider
      class SlugSequence
        SLUGS = [
          "sign-in",
          "verify-claim",
          "complete",
          "unauthorised"
        ]

        RESTRICTED_SLUGS = [
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

        def requires_authorisation?(slug)
          RESTRICTED_SLUGS.include?(slug)
        end

        def unauthorised_path(slug, failure_reason)
          Rails.application.routes.url_helpers.claim_path(
            self.class.module_parent::ROUTING_NAME,
            "unauthorised",
            failure_reason: failure_reason
          )
        end
      end
    end
  end
end
