module Journeys
  module EarlyYearsPayment
    module Provider
      module Start
        extend Base
        extend self

        ROUTING_NAME = "early-years-payment"
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
