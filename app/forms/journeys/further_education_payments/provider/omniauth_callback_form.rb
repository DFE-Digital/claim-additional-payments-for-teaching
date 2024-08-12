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
            dfe_sign_in_organisation_id: dfe_sign_in_organisation_id,
            dfe_sign_in_organisation_ukprn: dfe_sign_in_organisation_ukprn,
            dfe_sign_in_service_access: dfe_sign_in_service_access?
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

        def dfe_sign_in_organisation_id
          auth.dig("extra", "raw_info", "organisation", "id")
        end

        def dfe_sign_in_service_access?
          dfe_sign_in_user.service_access?
        end

        def dfe_sign_in_user
          @dfe_sign_in_user ||= DfeSignIn::Api::User.new(
            organisation_id: dfe_sign_in_organisation_id,
            user_id: dfe_sign_in_uid
          )
        end
      end
    end
  end
end
