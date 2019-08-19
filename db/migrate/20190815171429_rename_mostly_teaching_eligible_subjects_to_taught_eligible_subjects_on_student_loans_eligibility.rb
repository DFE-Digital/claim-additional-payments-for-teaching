class RenameMostlyTeachingEligibleSubjectsToTaughtEligibleSubjectsOnStudentLoansEligibility < ActiveRecord::Migration[5.2]
  def change
    rename_column :student_loans_eligibilities, :mostly_teaching_eligible_subjects, :taught_eligible_subjects
  end
end
