class CreateStudentLoansEligibilities < ActiveRecord::Migration[5.2]
  def change
    create_table :student_loans_eligibilities, id: :uuid do |t|
      t.timestamps
    end
  end
end
