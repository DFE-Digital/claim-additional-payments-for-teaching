class AddTrsFieldsToStudentLoansEligibilities < ActiveRecord::Migration[8.1]
  def change
    change_table :student_loans_eligibilities do |t|
      t.column :teacher_auth_teacher_reference_number, :string
      t.column :teacher_auth_email, :citext
      t.column :teacher_auth_verified_name, :text
      t.column :teacher_auth_verified_date_of_birth, :date
      t.column :teacher_auth_one_login_uid, :text
      t.column :teacher_auth_completed_at, :datetime
      t.column :trs_data_fetched_at, :datetime
    end
  end
end
