module Journeys
  module TeacherStudentLoanReimbursement
    class Session < Journeys::Session
      def journey_module
        Journeys::TeacherStudentLoanReimbursement
      end
    end
  end
end
