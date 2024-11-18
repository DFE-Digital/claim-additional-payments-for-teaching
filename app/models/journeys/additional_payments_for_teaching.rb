# frozen_string_literal: true

module Journeys
  module AdditionalPaymentsForTeaching
    extend Base
    extend self

    ROUTING_NAME = "additional-payments"
    VIEW_PATH = "additional_payments"
    I18N_NAMESPACE = "additional_payments"
    POLICIES = [Policies::EarlyCareerPayments, Policies::LevellingUpPremiumPayments]
    FORMS = {
      "claims" => {
        "induction-completed" => InductionCompletedForm,
        "itt-year" => IttAcademicYearForm,
        "nqt-in-academic-year-after-itt" => NqtInAcademicYearAfterIttForm,
        "eligible-degree-subject" => EligibleDegreeSubjectForm,
        "supply-teacher" => SupplyTeacherForm,
        "poor-performance" => PoorPerformanceForm,
        "entire-term-contract" => EntireTermContractForm,
        "employed-directly" => EmployedDirectlyForm,
        "qualification" => QualificationForm,
        "qualification-details" => QualificationDetailsForm,
        "eligible-itt-subject" => EligibleIttSubjectForm,
        "teaching-subject-now" => TeachingSubjectNowForm,
        "eligibility-confirmed" => EligibilityConfirmedForm,
        "correct-school" => CorrectSchoolForm,
        "reset-claim" => ResetClaimForm,
        "select-home-address" => SelectHomeAddressForm
      }
    }.freeze

    def set_a_reminder?(itt_academic_year:, policy:)
      policy_year = configuration.current_academic_year
      return false if policy_year >= policy::POLICY_END_YEAR

      next_year = policy_year + 1
      eligible_itt_years = JourneySubjectEligibilityChecker.selectable_itt_years_for_claim_year(next_year)
      eligible_itt_years.include?(itt_academic_year)
    end

    def requires_student_loan_details?
      true
    end
  end
end
