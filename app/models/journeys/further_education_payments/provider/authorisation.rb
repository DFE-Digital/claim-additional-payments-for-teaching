module Journeys
  module FurtherEducationPayments
    module Provider
      class Authorisation
        attr_reader :answers

        def initialize(answers)
          @answers = answers
        end

        def authorised?(slug)
          return false if failure_reason(slug).present?

          true
        end

        def failure_reason(slug)
          return :not_signed_in unless signed_in?
          return :no_service_access unless service_access?
          return :organisation_mismatch unless organisation_matches?
          # ...
          nil
        end

        private

        def signed_in?
          answers.dfe_sign_in_uid.present?
        end

        def organisation_matches?
          answers.dfe_sign_in_organisation_ukprn == answers.claim.school.ukprn
        end

        # FIXME RL: need to find out what the role codes should be
        def service_access?
          answers.dfe_sign_in_organisation_role_codes.include?("claim_verifier_access")
        end
      end
    end
  end
end

