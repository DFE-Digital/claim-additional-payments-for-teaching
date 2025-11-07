module Journeys
  module EarlyYearsPayment
    module Practitioner
      extend Base
      extend self

      ROUTING_NAME = "early-years-payment-practitioner"
      POLICIES = [Policies::EarlyYearsPayments]
      FORMS = [
        SignInForm,
        FindReferenceForm,
        PersonalBankAccountForm,
        HowWeUseYourInformationForm,
        CheckYourAnswersForm,
        ConfirmationForm,
        IneligibleForm
      ]

      def requires_student_loan_details?
        true
      end
    end
  end
end
