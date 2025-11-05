module Journeys
  module GetATeacherRelocationPayment
    extend Base
    extend self

    POLICIES = [Policies::InternationalRelocationPayments]
    FORMS = [
      PreviousPaymentReceivedForm,
      ApplicationRouteForm,
      StateFundedSecondarySchoolForm,
      ContractDetailsForm,
      StartDateForm,
      SubjectForm,
      ChangedWorkplaceOrNewContractForm,
      BreaksInEmploymentForm,
      VisaForm,
      EntryDateForm,
      InformationProvidedForm,
      NationalityForm,
      PassportNumberForm,
      HeadteacherDetailsForm,
      PersonalDetailsForm,
      CheckYourAnswersPartOneForm,
      CheckYourAnswersForm,
      ConfirmationForm,
      IneligibleForm
    ]

    def requires_student_loan_details?
      true
    end
  end
end
