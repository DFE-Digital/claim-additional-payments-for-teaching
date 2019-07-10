class AddStudentLoanStartDateToTslrclaim < ActiveRecord::Migration[5.2]
  def change
    add_column :tslr_claims, :student_loan_start_date, :integer
  end
end
