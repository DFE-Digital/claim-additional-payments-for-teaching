module Journeys
  module EarlyYearsPayment
    module Provider
      module Start
        extend Base
        extend self

        ROUTING_NAME = "early-years-payment"
        I18N_NAMESPACE = "early_years_payment_provider_start"
        POLICIES = [Policies::EarlyYearsPayments]

        FORMS = {
          "claims" => {
            "email-address" => EmailAddressForm,
            "check-your-email" => CheckYourEmailForm,
            "ineligible" => IneligibleForm
          }
        }
      end
    end
  end
end
