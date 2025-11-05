module Journeys
  module EarlyYearsPayment
    module Practitioner
      extend Base
      extend self

      ROUTING_NAME = "early-years-payment-practitioner"
      POLICIES = [Policies::EarlyYearsPayments]
      FORMS = {
        "claims" => {
          "sign-in" => SignInForm,
          "find-reference" => FindReferenceForm,
          "personal-bank-account" => PersonalBankAccountForm,
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
