module Journeys
  module EarlyYearsPayment
    module Practitioner
      extend Base
      extend self

      ROUTING_NAME = "early-years-payment-practitioner"
      VIEW_PATH = "early_years_payment/practitioner"
      I18N_NAMESPACE = "early_years_payment_practitioner"
      POLICIES = [Policies::EarlyYearsPayments]
      FORMS = {
        "claims" => {
          "find-reference" => FindReferenceForm,
          "personal-bank-account" => BankDetailsForm,
          "how-we-use-your-information" => HowWeUseYourInformationForm,
          "check-your-answers" => CheckYourAnswersForm,
          "confirmation" => ConfirmationForm,
          "ineligible" => IneligibleForm
        }
      }

      def requires_student_loan_details?
        true
      end
    end
  end
end
