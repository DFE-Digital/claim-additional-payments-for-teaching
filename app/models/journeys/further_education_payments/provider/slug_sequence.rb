module Journeys
  module FurtherEducationPayments
    module Provider
      class SlugSequence
        SLUGS = %w[
          sign-in
          verify-claim
          authorisation-failure
        ]

        AUTHORISED_SLUGS = %w[
          verify-claim
        ]

        DEAD_END_SLUGS = %w[
          authorisation-failure
        ]

        def self.verify_claim_url(claim)
          Rails.application.routes.url_helpers.landing_page_path(
            journey: module_parent::ROUTING_NAME,
            claim_id: claim.id
          )
        end

        # FIXME required but doesn't do any good without the claim
        def self.start_page_url
          Rails.application.routes.url_helpers.landing_page_path("further-education-payments-provider")
        end

        def initialize(journey_session)
          @journey_session = journey_session
        end

        def slugs
          SLUGS
        end

        # May use different auth depending on slug
        def authorisation_start(slug)
          "sign-in"
        end

        def requires_authorisation?(slug)
          AUTHORISED_SLUGS.include?(slug)
        end

        def dead_end_slugs
          DEAD_END_SLUGS
        end
      end
    end
  end
end
