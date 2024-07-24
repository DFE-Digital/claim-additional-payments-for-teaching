module Journeys
  module EarlyYearsPayment
    extend Base
    extend self

    ROUTING_NAME = "early-years-payment"
    VIEW_PATH = "early_years_payment"
    I18N_NAMESPACE = "early_years_payment"
    POLICIES = [Policies::EarlyYearsPayment]
    FORMS = {
      "claims" => {}
    }
  end
end
