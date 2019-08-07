class AddHadLeadershipPositionToStudentLoansEligibilities < ActiveRecord::Migration[5.2]
  def change
    add_column :student_loans_eligibilities, :had_leadership_position, :boolean
  end
end
