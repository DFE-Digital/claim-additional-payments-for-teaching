module Journeys
  module FurtherEducationPayments
    module Provider
      class Authorisation
        def initialize(answers:, slug:)
          @answers = answers
          @slug = slug
        end

        def failure_reason
          return :organisation_mismatch if organisation_mismatch?
          return :no_service_access unless answers.dfe_sign_in_service_access?
          return :claim_admin if claim_admin?
          return :incorrect_role unless role_permits_access?
          return :already_verified if already_verified? && slug != "complete"

          nil
        end

        private

        attr_reader :answers, :slug

        def organisation_mismatch?
          answers.claim.school.ukprn != answers.dfe_sign_in_organisation_ukprn
        end

        def role_permits_access?
          answers.dfe_sign_in_role_codes.include?(
            CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE
          )
        end

        def claim_admin?
          claim_admin_roles.any? do |role_code|
            answers.dfe_sign_in_role_codes.include?(role_code)
          end
        end

        def claim_admin_roles
          [
            DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE,
            DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE,
            DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE
          ]
        end

        def already_verified?
          answers.claim.eligibility.verified?
        end
      end
    end
  end
end
