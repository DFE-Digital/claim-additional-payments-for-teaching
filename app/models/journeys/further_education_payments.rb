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
        "building-and-construction-courses" => BuildingConstructionCoursesForm,
        "chemistry-courses" => ChemistryCoursesForm,
        "computing-courses" => ComputingCoursesForm,
        "early-years-courses" => EarlyYearsCoursesForm,
        "engineering-manufacturing-courses" => EngineeringManufacturingCoursesForm,
        "maths-courses" => MathsCoursesForm,
        "teaching-qualification" => TeachingQualificationForm,
        "poor-performance" => PoorPerformanceForm,
        "check-your-answers" => CheckYourAnswersForm,
        "ineligible" => IneligibleForm,
        "half-teaching-hours" => HalfTeachingHoursForm
      }
    }
  end
end
