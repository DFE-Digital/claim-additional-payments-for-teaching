module Journeys
  module TeacherStudentLoanReimbursement
    class Session < Journeys::Session
      attribute :answers, SessionAnswersType.new
    end
  end
end
