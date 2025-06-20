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
        "claim-school-results" => ClaimSchoolResultsForm,
        "qualification-details" => QualificationDetailsForm,
        "qts-year" => QtsYearForm,
        "subjects-taught" => SubjectsTaughtForm,
        "still-teaching" => StillTeachingForm,
        "leadership-position" => LeadershipPositionForm,
        "mostly-performed-leadership-duties" => MostlyPerformedLeadershipDutiesForm,
        "reset-claim" => ResetClaimForm,
        "select-claim-school" => SelectClaimSchoolForm,
        "select-home-address" => SelectHomeAddressForm,
        "eligibility-confirmed" => EligibilityConfirmedForm,
        "student-loan-amount" => StudentLoanAmountForm,
        "check-your-answers" => CheckYourAnswersForm,
        "confirmation" => ConfirmationForm,
        "ineligible" => IneligibleForm
      }
    }.freeze

    def requires_student_loan_details?
      true
    end
  end
end
