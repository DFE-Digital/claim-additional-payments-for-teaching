module Journeys
  module FurtherEducationPayments
    extend Base
    extend self

    ROUTING_NAME = "further-education-payments"
    VIEW_PATH = "further_education_payments"
    I18N_NAMESPACE = "further_education_payments"
    POLICIES = []
    FORMS = {
      "claims" => {
        "teaching-responsibilities" => TeachingResponsibilitiesForm
      }
    }
  end
end
