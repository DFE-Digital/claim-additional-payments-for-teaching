class AddStudentLoanPlanToTslrClaim < ActiveRecord::Migration[5.2]
  def change
    add_column :tslr_claims, :student_loan_plan, :integer
  end
end
