module Journeys
  module FurtherEducationPayments
    module Provider
      extend Base
      extend self

      ROUTING_NAME = "further-education-payments-provider"
      VIEW_PATH = "further_education_payments/provider"
      I18N_NAMESPACE = "further_education_payments_provider"

      POLICIES = []

      FORMS = {
        "claims" => {
          "verify-claim" => VerifyClaimForm,
          "complete" => CompleteForm,
          "unauthorised" => UnauthorisedForm,
          "expired-link" => ExpiredLinkForm,
          "already-verified" => AlreadyVerifiedForm
        }
      }

      CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE = "teacher_payments_claim_verifier"

      START_WITH_MAGIC_LINK = true

      def self.request_service_access_url(session)
        [
          "https://services.signin.education.gov.uk",
          "request-service", DfeSignIn.configuration.client_id,
          "users", session.answers.dfe_sign_in_uid
        ].join("/")
      end

      def self.sign_out_url
        dfe_sign_out_redirect_uri = URI.join(ENV.fetch("DFE_SIGN_IN_ISSUER"), "/session/end")

        post_logout_redirect_uri = URI.join(ENV.fetch("DFE_SIGN_IN_REDIRECT_BASE_URL"), "/further-education-payments-provider/auth/sign-out")
        client_id = DfeSignIn.configuration.client_id

        params = {
          post_logout_redirect_uri:,
          client_id:
        }

        dfe_sign_out_redirect_uri.query = URI.encode_www_form(params)
        dfe_sign_out_redirect_uri.to_s
      end

      def use_navigator?
        true
      end
    end
  end
end
