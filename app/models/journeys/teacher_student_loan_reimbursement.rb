# frozen_string_literal: true

module Journeys
  module TeacherStudentLoanReimbursement
    extend Base
    extend self

    ROUTING_NAME = "student-loans"
    VIEW_PATH = "student_loans"
    I18N_NAMESPACE = "student_loans"
    POLICIES = [Policies::StudentLoans]

    FORMS = {
      "claims" => {
        "claim-school" => ClaimSchoolForm,
        "qualification-details" => QualificationDetailsForm,
        "qts-year" => QtsYearForm,
        "subjects-taught" => SubjectsTaughtForm,
        "still-teaching" => StillTeachingForm,
        "leadership-position" => LeadershipPositionForm,
        "mostly-performed-leadership-duties" => MostlyPerformedLeadershipDutiesForm,
        "reset-claim" => ResetClaimForm,
        "postcode-search" => PostcodeSearchForm,
        "select-claim-school" => SelectClaimSchoolForm,
        "select-home-address" => SelectHomeAddressForm
      }
    }.freeze

    def self.eligibility_checkers(answers)
      POLICIES.map { |policy| policy::EligibilityChecker.new(shim.answers) }
    end
  end
end
