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

        def self.provider_journey?
          true
        end
      end
    end
  end
end
