module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        extend Base
        extend self

        ROUTING_NAME = "early-years-payment-provider"
        VIEW_PATH = "early_years_payment/provider/authenticated"
        I18N_NAMESPACE = "early_years_payment_provider_authenticated"
        POLICIES = [Policies::EarlyYearsPayments]
        FORMS = {
          "claims" => {
            "consent" => ConsentForm,
            "current-nursery" => CurrentNurseryForm,
            "paye-reference" => PayeReferenceForm,
            "claimant-name" => ClaimantNameForm,
            "start-date" => StartDateForm,
            "child-facing" => ChildFacingForm,
            "returner" => ReturnerForm,
            "employee-email" => EmployeeEmailForm,
            "check-your-answers" => CheckYourAnswersForm
          }
        }
        START_WITH_MAGIC_LINK = true
      end
    end
  end
end
