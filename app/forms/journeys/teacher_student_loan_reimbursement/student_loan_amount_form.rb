module Journeys
  module TeacherStudentLoanReimbursement
    class StudentLoanAmountForm < Form
      def completed?
        journey_session.answers.student_loan_amount_seen
      end

      def save
        journey_session.answers.update!(
          student_loan_amount_seen: true
        )
      end
    end
  end
end
