module Journeys
  module FurtherEducationPayments
    module Provider
      extend Base
      extend self

      ROUTING_NAME = "further-education-payments-provider"
      VIEW_PATH = "further_education_payments/provider"
      I18N_NAMESPACE = "further_education_payments_provider"

      POLICIES = []

      # FIXME RL find out what this role should be
      CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE = "FIXME_RL"

      FORMS = {
        "claims" => {
          "verify-claim" => VerifyClaimForm
        }
      }
    end
  end
end
