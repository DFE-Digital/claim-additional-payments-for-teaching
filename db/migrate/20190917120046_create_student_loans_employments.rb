class CreateStudentLoansEmployments < ActiveRecord::Migration[5.2]
  def change
    create_table :student_loans_employments, id: :uuid do |t|
      t.references :eligibility, type: :uuid, foreign_key: {to_table: :student_loans_eligibilities}, index: {name: "student_loans_employments_on_eligibility_id"}
      t.references :school, type: :uuid, foreign_key: {to_table: :schools}

      t.boolean "biology_taught"
      t.boolean "chemistry_taught"
      t.boolean "computer_science_taught"
      t.boolean "languages_taught"
      t.boolean "physics_taught"
      t.boolean "taught_eligible_subjects"
      t.decimal "student_loan_repayment_amount", precision: 7, scale: 2

      t.timestamps
    end
  end
end
