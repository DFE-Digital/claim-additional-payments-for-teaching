class AddSubjectsTaughtAttributesToStudentLoansEligibilities < ActiveRecord::Migration[5.2]
  def change
    change_table :student_loans_eligibilities do |t|
      t.boolean :biology_taught
      t.boolean :chemistry_taught
      t.boolean :computer_science_taught
      t.boolean :languages_taught
      t.boolean :physics_taught
      t.boolean :mostly_teaching_eligible_subjects
    end
  end
end
