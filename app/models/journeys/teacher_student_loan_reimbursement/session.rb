module Journeys
  module TeacherStudentLoanReimbursement
    class Session < Journeys::Session
      attribute :answers, SessionAnswersType.new

      def journey_module
        Journeys::TeacherStudentLoanReimbursement
      end
    end
  end
end
