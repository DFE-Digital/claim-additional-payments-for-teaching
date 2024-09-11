module Journeys
  module TeacherStudentLoanReimbursement
    class AnswersStudentLoansDetailsUpdater < Journeys::AnswersStudentLoansDetailsUpdater
      def save!
        journey_session.answers.assign_attributes(
          student_loan_repayment_amount: student_loans_data.total_repayment_amount,
          has_student_loan: student_loans_data.has_student_loan_for_student_loan_policy,
          student_loan_plan: student_loans_data.student_loan_plan_for_student_loan_policy,
          submitted_using_slc_data: student_loans_data.found_data?
        )

        journey_session.save!
      rescue => e
        Rollbar.error(e)
      end
    end
  end
end
