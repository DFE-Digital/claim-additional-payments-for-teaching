# frozen_string_literal: true

module Journeys
  module TeacherStudentLoanReimbursement
    extend Base
    extend self

    ROUTING_NAME = "student-loans"
    VIEW_PATH = "student_loans"
    I18N_NAMESPACE = "student_loans"
    POLICIES = [Policies::StudentLoans]
  end
end
