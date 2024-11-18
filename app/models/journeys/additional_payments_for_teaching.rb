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

    def selectable_subject_symbols(journey_session)
      return [] if journey_session.answers.itt_academic_year&.none?

      if journey_session.answers.nqt_in_academic_year_after_itt
        EligibilityChecker.new(journey_session: journey_session)
          .potentially_still_eligible.map do |policy|
            policy.current_and_future_subject_symbols(
              claim_year: journey_session.answers.policy_year,
              itt_year: journey_session.answers.itt_academic_year
            )
          end.flatten.uniq
      elsif journey_session.answers.policy_year.in?(EligibilityCheckable::COMBINED_ECP_AND_LUP_POLICY_YEARS_BEFORE_FINAL_YEAR)
        # they get the standard, unchanging LUP subject set because they won't have qualified in time for ECP by 2022/2023
        # and they won't have given an ITT year
        Policies::LevellingUpPremiumPayments.fixed_subject_symbols
      else
        []
      end
    end
  end
end
