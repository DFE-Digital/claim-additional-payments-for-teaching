module Journeys
  module TeacherStudentLoanReimbursement
    class StudentLoanAmountForm < Form
      def completed?
        journey_session.answers.student_loan_amount_seen
      end

      def save
        journey_session.answers.assign_attributes(
          student_loan_amount_seen: true
        )

        journey_session.save!
      end
    end
  end
end
