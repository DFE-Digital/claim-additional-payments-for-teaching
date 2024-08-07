module Journeys
  module FurtherEducationPayments
    module Provider
      class Authorisation
        include ActiveModel::Model

        def initialize(answers:, slug:)
          @answers = answers
          @slug = slug
        end

        def authorised?
          failure_reason.nil?
        end

        def failure_reason
          return :not_signed_in unless signed_in?
          return :no_service_access unless service_access?
          return :organisation_mismatch unless organisation_matches?
          # ...
          nil
        end

        private

        attr_reader :answers, :slug

        def signed_in?
          answers.dfe_sign_in_uid.present?
        end

        def organisation_matches?
          # FIXME RL temp returning `true` until we've added school to the FE
          # eligibility
          return true

          answers.dfe_sign_in_organisation_ukprn == answers.claim.school.ukprn
        end

        def service_access?
          answers.dfe_sign_in_organisation_role_codes.include?(
            CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE
          )
        end
      end
    end
  end
end
