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
            dfe_sign_in_service_access: dfe_sign_in_service_access?,
            dfe_sign_in_role_codes: dfe_sign_in_role_codes,
            dfe_sign_in_first_name: dfe_sign_in_first_name,
            dfe_sign_in_last_name: dfe_sign_in_last_name,
            dfe_sign_in_email: dfe_sign_in_email
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

        def dfe_sign_in_role_codes
          return [] unless dfe_sign_in_service_access?

          dfe_sign_in_user.role_codes
        end

        def dfe_sign_in_first_name
          auth.dig("info", "first_name")
        end

        def dfe_sign_in_last_name
          auth.dig("info", "last_name")
        end

        def dfe_sign_in_email
          auth.dig("info", "email")
        end
      end
    end
  end
end
