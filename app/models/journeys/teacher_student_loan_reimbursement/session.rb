module Journeys
  module TeacherStudentLoanReimbursement
    class Session < Journeys::Session
      attribute :answers, SessionAnswersType.new

      def answers
        super.tap { it.session = self }
      end
    end
  end
end
