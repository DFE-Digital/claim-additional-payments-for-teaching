module Journeys
  module TargetedRetentionIncentivePayments
    extend Base
    extend self

    POLICIES = [Policies::TargetedRetentionIncentivePayments]
    FORMS = [
      CheckEligibilityIntroForm,
      CurrentSchoolForm,
      SelectCurrentSchoolForm,
      CorrectSchoolForm,
      NqtInAcademicYearAfterIttForm,
      SupplyTeacherForm,
      EntireTermContractForm,
      EmployedDirectlyForm,
      PoorPerformanceForm,
      QualificationDetailsForm,
      QualificationForm,
      IttYearForm,
      EligibleIttSubjectForm,
      EligibleDegreeSubjectForm,
      TeachingSubjectNowForm,
      CheckYourAnswersPartOneForm,
      CheckYourAnswersForm,
      ConfirmationForm,
      EligibilityConfirmedForm,
      FutureEligibilityForm,
      IneligibleForm,
      ResetClaimForm
    ]

    NONE_OF_THE_ABOVE_ACADEMIC_YEAR = "itt_academic_year_none"

    def requires_student_loan_details?
      true
    end

    def set_a_reminder?(itt_year)
      Policies::TargetedRetentionIncentivePayments.set_a_reminder?(itt_year)
    end

    def uses_reminders?
      true
    end
  end
end
