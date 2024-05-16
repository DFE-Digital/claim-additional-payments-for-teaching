module Journeys
  module TeacherStudentLoanReimbursement
    class SessionAnswers < Journeys::SessionAnswers
      attribute :qts_award_year, :string
      attribute :claim_school_id, :string # UUID
      attribute :employment_status, :string
      attribute :biology_taught, :boolean
      attribute :chemistry_taught, :boolean
      attribute :computing_taught, :boolean
      attribute :languages_taught, :boolean
      attribute :physics_taught, :boolean
      attribute :taught_eligible_subjects, :boolean
      attribute :student_loan_repayment_amount, :decimal
      attribute :had_leadership_position, :boolean
      attribute :mostly_performed_leadership_duties, :boolean
      attribute :claim_school_somewhere_else, :boolean
    end
  end
end
