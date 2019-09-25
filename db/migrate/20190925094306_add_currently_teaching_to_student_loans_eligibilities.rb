class AddCurrentlyTeachingToStudentLoansEligibilities < ActiveRecord::Migration[5.2]
  def change
    add_column :student_loans_eligibilities, :currently_teaching, :boolean
  end
end
