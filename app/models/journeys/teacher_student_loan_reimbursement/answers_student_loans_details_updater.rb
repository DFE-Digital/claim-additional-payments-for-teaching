module Journeys
  module TeacherStudentLoanReimbursement
    class AnswersStudentLoansDetailsUpdater < Journeys::AnswersStudentLoansDetailsUpdater
      def save!
        journey_session.answers.assign_attributes(
          award_amount: student_loans_data.total_repayment_amount
        )

        super
      end
    end
  end
end
