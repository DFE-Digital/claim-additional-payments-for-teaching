module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        extend Base
        extend self

        ROUTING_NAME = "early-years-payment-provider"
        POLICIES = [Policies::EarlyYearsPayments]
        FORMS = [
          ConsentForm,
          CurrentNurseryForm,
          PayeReferenceForm,
          ClaimantNameForm,
          StartDateForm,
          ContractTypeForm,
          ChildFacingForm,
          ReturnerForm,
          ReturnerWorkedWithChildrenForm,
          ReturnerContractTypeForm,
          EmployeeEmailForm,
          CheckYourAnswersForm,
          ConfirmationForm,
          IneligibleForm,
          ExpiredLinkForm
        ]
        START_WITH_MAGIC_LINK = true
      end
    end
  end
end
