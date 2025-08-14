module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        extend Base
        extend self

        ROUTING_NAME = "early-years-payment-provider-alternative-idv"
        VIEW_PATH = "early_years_payment/provider/alternative_idv"
        I18N_NAMESPACE = "early_years_payment_provider_alternative_idv"
        POLICIES = [Policies::EarlyYearsPayments]
        FORMS = {
          "claims" => {
            "claimant-employed-by-nursery" => ClaimantEmployedByNurseryForm,
            "claimant-personal-details" => ClaimantPersonalDetailsForm,
            "check-answers" => CheckAnswersForm,
            "confirmation" => ConfirmationForm,
            "claimant-not-employed-by-nursery" => ClaimantNotEmployedByNurseryForm
          }
        }

        def self.verification_url(claim)
          params = {claim_reference: claim.reference}.to_query

          "https://#{ENV["CANONICAL_HOSTNAME"]}/#{start_page_url}?#{params}"
        end
      end
    end
  end
end
