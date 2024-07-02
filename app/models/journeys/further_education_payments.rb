module Journeys
  module FurtherEducationPayments
    extend Base
    extend self

    ROUTING_NAME = "further-education-payments"
    VIEW_PATH = "further_education_payments"
    I18N_NAMESPACE = "further_education_payments"
    POLICIES = []
    FORMS = {
      "claims" => {
        "teaching-responsibilities" => TeachingResponsibilitiesForm,
        "further-education-provision-search" => FurtherEducationProvisionSearchForm,
        "select-provision" => SelectProvisionForm,
        "contract-type" => ContractTypeForm,
        "teaching-hours-per-week" => TeachingHoursPerWeekForm,
        "further-education-teaching-start-year" => FurtherEducationTeachingStartYearForm,
        "subjects-taught" => SubjectsTaughtForm,
        "teaching-qualification" => TeachingQualificationForm
      }
    }
  end
end
