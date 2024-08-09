module Journeys
  module FurtherEducationPayments
    module Provider
      class OmniauthCallbackForm
        def initialize(journey_session:, auth:)
          @journey_session = journey_session
          @auth = auth
        end

        def save!
          journey_session.answers.assign_attributes(
            dfe_sign_in_uid: dfe_sign_in_uid,
            dfe_sign_in_organisation_ukprn: dfe_sign_in_organisation_ukprn
          )

          journey_session.save!
        end

        private

        attr_reader :journey_session, :auth

        def dfe_sign_in_uid
          auth["uid"]
        end

        def dfe_sign_in_organisation_ukprn
          auth.dig("extra", "raw_info", "organisation", "ukprn")
        end
      end
    end
  end
end
