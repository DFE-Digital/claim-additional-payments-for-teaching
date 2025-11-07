module Journeys
  module EarlyYearsPayment
    module Provider
      module Start
        extend Base
        extend self

        ROUTING_NAME = "early-years-payment"
        POLICIES = [Policies::EarlyYearsPayments]

        FORMS = [
          EmailAddressForm,
          CheckYourEmailForm,
          IneligibleForm
        ]
      end
    end
  end
end
