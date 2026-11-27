module Journeys
  module TeacherStudentLoanReimbursement
    class NationalInsuranceNumberForm < ::NationalInsuranceNumberForm
      def save
        return false unless super

        journey_session.answers.update!(student_loan_amount_seen: false)
        AnswersStudentLoansDetailsUpdater.call(journey_session)

        true
      end
    end
  end
end
