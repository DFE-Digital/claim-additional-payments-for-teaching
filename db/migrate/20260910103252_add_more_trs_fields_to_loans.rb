class AddMoreTrsFieldsToLoans < ActiveRecord::Migration[8.1]
  def change
    change_table :student_loans_eligibilities do |t|
      t.column :teacher_auth_first_name, :string
      t.column :teacher_auth_last_name, :string
      t.column :teacher_auth_national_insurance_number, :string
      t.column :teacher_auth_date_of_birth, :date
    end
  end
end
