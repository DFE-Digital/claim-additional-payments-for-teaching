module Journeys
  module FurtherEducationPayments
    module Provider
      class SlugSequence
        SLUGS = %w[
          sign-in
          verify-claim
        ]

        AUTHORISED_SLUGS = %w[
          verify-claim
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
        end

        def requires_authorisation?(slug)
          AUTHORISED_SLUGS.include?(slug)
        end
      end
    end
  end
end
