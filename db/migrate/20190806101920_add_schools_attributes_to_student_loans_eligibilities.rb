class AddSchoolsAttributesToStudentLoansEligibilities < ActiveRecord::Migration[5.2]
  def change
    change_table :student_loans_eligibilities do |t|
      t.references :claim_school, type: :uuid, foreign_key: {to_table: :schools}
      t.references :current_school, type: :uuid, foreign_key: {to_table: :schools}
      t.integer :employment_status
    end
  end
end
