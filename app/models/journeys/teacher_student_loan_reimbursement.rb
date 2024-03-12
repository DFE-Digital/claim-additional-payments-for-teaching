# frozen_string_literal: true

module Journeys
  module TeacherStudentLoanReimbursement
    ROUTING_NAME = "student-loans"
    VIEW_PATH = "student_loans"
    I8N_NAMESPACE = "student_loans"
    POLICIES = [Policies::StudentLoans]
  end
end
