module Journeys
  module FurtherEducationPayments
    module Provider
      class SlugSequence
        SLUGS = [
          "sign-in",
          "verify-claim",
          "complete",
          "unauthorised",
          "expired-link"
        ]

        RESTRICTED_SLUGS = [
          "verify-claim",
          "complete"
        ]

        def self.verify_claim_url(claim)
          Rails.application.routes.url_helpers.new_claim_url(
            module_parent::ROUTING_NAME,
            answers: {
              claim_id: claim.id
            },
            host: ENV.fetch("CANONICAL_HOSTNAME"),
            protocol: "https"
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
          if @journey_session.answers.claim.rejected?
            return [
              "expired-link",
              # FormSubmittable requires a "next_slug", if the claim is
              # rejected there isn't a next slug
              "expired-link"
            ]
          end

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
