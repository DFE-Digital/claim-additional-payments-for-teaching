module Journeys
  module TargetedRetentionIncentivePayments
    extend Base
    extend self

    ROUTING_NAME = "targeted-retention-incentive-payments"
    VIEW_PATH = "targeted_retention_incentive_payments"
    I18N_NAMESPACE = "targeted_retention_incentive_payments"
    POLICIES = [Policies::TargetedRetentionIncentivePayments]
    FORMS = {
      "claims" => {
        "nqt-in-academic-year-after-itt" => NqtInAcademicYearAfterIttForm,
        "supply-teacher" => SupplyTeacherForm,
        "poor-performance" => PoorPerformanceForm,
        "qualification" => QualificationForm,
        "itt-year" => IttAcademicYearForm,
        "eligible-itt-subject" => EligibleIttSubjectForm,
        "teaching-subject-now" => TeachingSubjectNowForm,
        "check-your-answers-part-one" => CheckYourAnswersPartOneForm,
        "eligibility-confirmed" => EligibilityConfirmedForm,
      }
    }

    NONE_OF_THE_ABOVE_ACADEMIC_YEAR = "itt_academic_year_none"

    def use_navigator?
      true
    end

    def requires_student_loan_details?
      true
    end
  end
end
