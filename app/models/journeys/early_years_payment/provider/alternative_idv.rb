module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        extend Base
        extend self

        START_WITH_MAGIC_LINK = true
        ROUTING_NAME = "early-years-payment-provider-alternative-idv"
        VIEW_PATH = "early_years_payment/provider/alternative_idv"
        I18N_NAMESPACE = "early_years_payment_provider_alternative_idv"
        POLICIES = [Policies::EarlyYearsPayments]
        FORMS = {
          "claims" => {
            "email-verification" => EmailVerificationForm,
            "claimant-employed-by-nursery" => ClaimantEmployedByNurseryForm,
            "claimant-personal-details" => ClaimantPersonalDetailsForm,
            "check-answers" => CheckAnswersForm,
            "confirmation" => ConfirmationForm,
            "claimant-not-employed-by-nursery" => ClaimantNotEmployedByNurseryForm,
            "ineligible" => IneligibleForm
          }
        }

        def self.verification_url(claim)
          "https://#{ENV["CANONICAL_HOSTNAME"]}#{verification_path(claim)}"
        end

        def self.verification_path(claim)
          params = {
            alternative_idv_reference: claim.eligibility.alternative_idv_reference
          }.to_query

          "#{start_page_url}?#{params}"
        end

        def self.send_alternative_idv_request!(claim)
          reference = nil

          loop do
            reference = SecureRandom.urlsafe_base64(16)

            break unless Policies::EarlyYearsPayments::Eligibility.exists?(
              alternative_idv_reference: reference
            )
          end

          claim.eligibility.update!(alternative_idv_reference: reference)

          EarlyYearsPaymentsMailer
            .provider_alternative_idv_request(claim)
            .deliver_later
        end
      end
    end
  end
end
