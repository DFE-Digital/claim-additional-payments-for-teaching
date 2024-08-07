module Journeys
  module EarlyYearsPayment
    module Start
      extend Base
      extend self

      ROUTING_NAME = "early-years-payment"
      VIEW_PATH = "early_years_payment/start"
      I18N_NAMESPACE = "early_years_payment_start"
      POLICIES = [Policies::EarlyYearsPayments]
      FORMS = {
        "claims" => {
          "email-address" => EmailAddressForm
        }
      }
    end
  end
end
