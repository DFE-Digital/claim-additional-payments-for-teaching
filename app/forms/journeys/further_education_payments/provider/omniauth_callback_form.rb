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
            dfe_sign_in_organisation_name: dfe_sign_in_organisation_name,
            dfe_sign_in_service_access: dfe_sign_in_service_access?,
            dfe_sign_in_role_codes: dfe_sign_in_role_codes,
            dfe_sign_in_first_name: dfe_sign_in_first_name,
            dfe_sign_in_last_name: dfe_sign_in_last_name,
            dfe_sign_in_email: dfe_sign_in_email,
            claim_started_verified: journey_session.answers.claim.eligibility.verified?
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

        def dfe_sign_in_organisation_name
          auth.dig("extra", "raw_info", "organisation", "name")
        end

        def dfe_sign_in_service_access?
          dfe_sign_in_user.service_access?
        end

        def dfe_sign_in_user
          @dfe_sign_in_user ||= if DfESignIn.bypass?
            StubApiUser.new(auth)
          else
            DfeSignIn::Api::User.new(
              user_type: "provider",
              organisation_id: dfe_sign_in_organisation_id,
              user_id: dfe_sign_in_uid
            )
          end
        end

        def dfe_sign_in_role_codes
          return [] unless dfe_sign_in_service_access?

          dfe_sign_in_user.role_codes
        end

        def dfe_sign_in_first_name
          auth.dig("info", "first_name") || dfe_sign_in_api_user&.first_name
        end

        def dfe_sign_in_last_name
          auth.dig("info", "last_name") || dfe_sign_in_api_user&.last_name
        end

        def dfe_sign_in_email
          auth.dig("info", "email")
        end

        class ApiUser < Struct.new(:first_name, :last_name, keyword_init: true); end

        def dfe_sign_in_api_user
          return @dfe_sign_in_api_user if @dfe_sign_in_api_user

          ukprn = journey_session.answers.claim.school.ukprn

          client = DfeSignIn::Api::Client.new(client_id: ENV.fetch("DFE_SIGN_IN_API_CLIENT_ID"))

          uri = URI(DfeSignIn.configuration_for_client_id(ENV.fetch("DFE_SIGN_IN_API_CLIENT_ID")).base_url)
          uri.path = "/organisations/#{ukprn}/users"
          uri.query = {email: dfe_sign_in_email}.to_query

          response = client.dfe_sign_in_request(uri)

          return unless response.code == "200"

          data = JSON.parse(response.body)
          users = data.fetch("users")
          user = users.detect { |user| user["email"] == dfe_sign_in_email }

          return unless user.present?

          @dfe_sign_in_api_user = ApiUser.new(
            first_name: user.fetch("firstName"),
            last_name: user.fetch("lastName")
          )
        rescue JSON::ParserError, KeyError => e
          raise e if Rails.env.development?
        end

        class StubApiUser
          def initialize(params)
            @params = params
          end

          def role_codes
            @params.fetch("roles", {}).values.compact_blank
          end

          def service_access?
            @params.fetch("service_access", false)
          end
        end
      end
    end
  end
end
