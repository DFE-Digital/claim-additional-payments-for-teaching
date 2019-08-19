class AddMostlyPerformedLeadershipDutiesToStudentLoansEligibilities < ActiveRecord::Migration[5.2]
  def change
    add_column :student_loans_eligibilities, :mostly_performed_leadership_duties, :boolean
  end
end
