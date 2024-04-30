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
      "claim-school" => ClaimSchoolForm,
      "qualification-details" => QualificationDetailsForm,
      "qts-year" => QtsYearForm,
      "subjects-taught" => SubjectsTaughtForm,
      "leadership-position" => LeadershipPositionForm,
      "mostly-performed-leadership-duties" => MostlyPerformedLeadershipDutiesForm
    }
  end
end
