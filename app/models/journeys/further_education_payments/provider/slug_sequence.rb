module Journeys
  module FurtherEducationPayments
    module Provider
      class SlugSequence
        SLUGS = [
          "sign-in",
          "unauthorised",
          "verify-claim",
          "complete",
          "expired-link",
          "already-verified"
        ]

        RESTRICTED_SLUGS = [
          "verify-claim"
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

        attr_reader :journey_session

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

          array = []
          array << "sign-in"

          if already_verified?
            array << "already-verified"
            return array
          end

          if unauthorised?
            array << "unauthorised"
            return array
          end

          array << "verify-claim"
          array << "complete"
          array
        end

        private

        def already_verified?
          return true if journey_session.answers.claim_started_verified == true

          false
        end

        def unauthorised?
          auth.failure_reason.present?
        end

        def auth
          Authorisation.new(
            answers: journey_session.answers
          )
        end
      end
    end
  end
end
