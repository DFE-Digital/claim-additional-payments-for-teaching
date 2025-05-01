module Journeys
  module TeacherStudentLoanReimbursement
    class IneligibleForm < Form
      def save
        true
      end
    end
  end
end
