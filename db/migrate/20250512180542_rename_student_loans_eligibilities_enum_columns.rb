class RenameStudentLoansEligibilitiesEnumColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :student_loans_eligibilities, :qts_award_year
    remove_column :student_loans_eligibilities, :employment_status

    Policies::StudentLoans::Eligibility.reset_column_information

    rename_column :student_loans_eligibilities, :qts_award_year_string, :qts_award_year
    rename_column :student_loans_eligibilities, :employment_status_string, :employment_status
  end
end
