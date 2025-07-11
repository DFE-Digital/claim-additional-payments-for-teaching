module Journeys
  module GetATeacherRelocationPayment
    extend Base
    extend self

    ROUTING_NAME = "get-a-teacher-relocation-payment"
    VIEW_PATH = "get_a_teacher_relocation_payment"
    I18N_NAMESPACE = "get_a_teacher_relocation_payment"
    POLICIES = [Policies::InternationalRelocationPayments]
    FORMS = {
      "claims" => {
        "previous-payment-received" => PreviousPaymentReceivedForm,
        "application-route" => ApplicationRouteForm,
        "state-funded-secondary-school" => StateFundedSecondarySchoolForm,
        "contract-details" => ContractDetailsForm,
        "start-date" => StartDateForm,
        "subject" => SubjectForm,
        "changed-workplace-or-new-contract" => ChangedWorkplaceOrNewContractForm,
        "breaks-in-employment" => BreaksInEmploymentForm,
        "visa" => VisaForm,
        "entry-date" => EntryDateForm,
        "information-provided" => InformationProvidedForm,
        "nationality" => NationalityForm,
        "passport-number" => PassportNumberForm,
        "headteacher-details" => HeadteacherDetailsForm,
        "personal-details" => PersonalDetailsForm,
        "check-your-answers-part-one" => CheckYourAnswersPartOneForm,
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
