module Journeys
  module FurtherEducationPayments
    extend Base
    extend self

    ROUTING_NAME = "further-education-payments"
    VIEW_PATH = "further_education_payments"
    I18N_NAMESPACE = "further_education_payments"
    POLICIES = [Policies::FurtherEducationPayments]
    FORMS = {
      "claims" => {
        "sign-in" => SignInForm,
        "identity-verification" => IdentityVerificationForm,
        "previously-claimed" => PreviouslyClaimedForm,
        "have-one-login-account" => HaveOneLoginAccountForm,
        "check-eligibility-intro" => CheckEligibilityIntroForm,
        "teaching-responsibilities" => TeachingResponsibilitiesForm,
        "further-education-provision-search" => FurtherEducationProvisionSearchForm,
        "select-provision" => SelectProvisionForm,
        "contract-type" => ContractTypeForm,
        "fixed-term-contract" => FixedTermContractForm,
        "taught-at-least-one-term" => TaughtAtLeastOneTermForm,
        "teaching-hours-per-week" => TeachingHoursPerWeekForm,
        "teaching-hours-per-week-next-term" => TeachingHoursPerWeekNextTermForm,
        "further-education-teaching-start-year" => FurtherEducationTeachingStartYearForm,
        "subjects-taught" => SubjectsTaughtForm,
        "building-construction-courses" => BuildingConstructionCoursesForm,
        "chemistry-courses" => ChemistryCoursesForm,
        "computing-courses" => ComputingCoursesForm,
        "early-years-courses" => EarlyYearsCoursesForm,
        "engineering-manufacturing-courses" => EngineeringManufacturingCoursesForm,
        "maths-courses" => MathsCoursesForm,
        "physics-courses" => PhysicsCoursesForm,
        "check-your-answers-part-one" => CheckYourAnswersPartOneForm,
        "information-provided" => InformationProvidedForm,
        "teaching-qualification" => TeachingQualificationForm,
        "poor-performance" => PoorPerformanceForm,
        "check-your-answers" => CheckYourAnswersForm,
        "half-teaching-hours" => HalfTeachingHoursForm,
        "hours-teaching-eligible-subjects" => HoursTeachingEligibleSubjectsForm,
        "passport" => PassportForm,
        "eligible" => EligibleForm,
        "ineligible" => IneligibleForm,
        "teacher-reference-number" => TeacherReferenceNumberForm,
        "confirmation" => ConfirmationForm
      }
    }

    def requires_student_loan_details?
      true
    end

    def uses_reminders?
      true
    end
  end
end
