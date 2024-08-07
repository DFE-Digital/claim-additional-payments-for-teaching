module Journeys
  module FurtherEducationPayments
    module Provider
      extend Base
      extend self

      ROUTING_NAME = "further-education-payments-provider"
      VIEW_PATH = "further_education_payments/provider"
      I18N_NAMESPACE = "further_education_payments_provider"

      POLICIES = []

      # FIXME RL replace the one of these in the verification class
      # with this
      CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE = "fixme_rl"

      FORMS = {
        "claims" => {
          "verify-claim" => VerifyClaimForm,
        }
      }
    end
  end
end
