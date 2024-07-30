module Journeys
  module EarlyYearsPayment
    module Provider
      extend Base
      extend self

      ROUTING_NAME = "early-years-payment-provider"
      VIEW_PATH = "early_years_payment/provider"
      I18N_NAMESPACE = "early_years_payment_provider"
      POLICIES = [Policies::EarlyYearsPayment]
      FORMS = {
        "claims" => {}
      }
    end
  end
end
