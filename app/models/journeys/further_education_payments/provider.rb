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
          "verify-claim" => VerifyClaimForm
        }
      }

      CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE = "teacher_payments_claim_verifier"
    end
  end
end
