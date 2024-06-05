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
        "postcode-search" => PostcodeSearchForm,
        "select-home-address" => SelectHomeAddressForm
      },
      "reminders" => {
        "personal-details" => Reminders::PersonalDetailsForm,
        "email-verification" => Reminders::EmailVerificationForm
      }
    }.freeze

    def self.eligibility_checkers(answers)
      POLICIES.map { |policy| policy::EligibilityChecker.new(answers) }
    end
  end
end
