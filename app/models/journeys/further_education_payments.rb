module Journeys
  module FurtherEducationPayments
    extend Base
    extend self

    POLICIES = [Policies::FurtherEducationPayments]
    FORMS = [
      SignInForm,
      PreviouslyClaimedForm,
      HaveOneLoginAccountForm,
      ExistingProgressForm,
      CheckEligibilityIntroForm,
      TeachingResponsibilitiesForm,
      FurtherEducationProvisionSearchForm,
      SelectProvisionForm,
      ContractTypeForm,
      FixedTermContractForm,
      TaughtAtLeastOneTermForm,
      TeachingHoursPerWeekForm,
      FurtherEducationTeachingStartYearForm,
      SubjectsTaughtForm,
      BuildingConstructionCoursesForm,
      ChemistryCoursesForm,
      ComputingCoursesForm,
      EarlyYearsCoursesForm,
      EngineeringManufacturingCoursesForm,
      MathsCoursesForm,
      PhysicsCoursesForm,
      CheckYourAnswersPartOneForm,
      IdentityVerificationForm,
      WorkEmailAccessForm,
      NoWorkEmailAccessForm,
      WorkEmailForm,
      WorkEmailVerificationForm,
      InformationProvidedForm,
      TeachingQualificationForm,
      PoorPerformanceForm,
      CheckYourAnswersForm,
      HalfTeachingHoursForm,
      HoursTeachingEligibleSubjectsForm,
      PassportForm,
      EligibleForm,
      IneligibleForm,
      TeacherReferenceNumberForm,
      ConfirmationForm
    ]

    def requires_student_loan_details?
      true
    end

    def uses_reminders?
      true
    end
  end
end
