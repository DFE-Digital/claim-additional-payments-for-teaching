module Journeys
  module TeacherStudentLoanReimbursement
    class Session < Journeys::Session
      has_many_attached :employment_proofs
    end
  end
end
