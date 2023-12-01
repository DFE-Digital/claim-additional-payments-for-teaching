class CreateStudentLoansData < ActiveRecord::Migration[7.0]
  def change
    create_table :student_loans_data, id: :uuid do |t|
      t.string :claim_reference
      t.string :nino
      t.string :full_name
      t.date :date_of_birth
      t.string :policy_name
      t.integer :no_of_plans_currently_repaying
      t.integer :plan_type_of_deduction
      t.float :amount
      t.timestamps
    end

    add_index :student_loans_data, :claim_reference
    add_index :student_loans_data, :nino
  end
end
