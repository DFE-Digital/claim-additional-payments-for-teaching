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
        "current-school" => CurrentSchoolForm,
        "correct-school" => CorrectSchoolForm,
        "nqt-in-academic-year-after-itt" => NqtInAcademicYearAfterIttForm,
        "supply-teacher" => SupplyTeacherForm,
        "entire-term-contract" => EntireTermContractForm,
        "employed-directly" => EmployedDirectlyForm,
        "poor-performance" => PoorPerformanceForm,
        "qualification-details" => QualificationDetailsForm,
        "qualification" => QualificationForm,
        "itt-year" => IttAcademicYearForm,
        "eligible-itt-subject" => EligibleIttSubjectForm,
        "eligible-degree-subject" => EligibleDegreeSubjectForm,
        "teaching-subject-now" => TeachingSubjectNowForm,
        "check-your-answers-part-one" => CheckYourAnswersPartOneForm,
        "check-your-answers" => CheckYourAnswersForm,
        "confirmation" => ConfirmationForm,
        "eligibility-confirmed" => EligibilityConfirmedForm,
        "future-eligibility" => FutureEligibilityForm,
        "ineligible" => IneligibleForm,
        "reset-claim" => ResetClaimForm
      }
    }

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
