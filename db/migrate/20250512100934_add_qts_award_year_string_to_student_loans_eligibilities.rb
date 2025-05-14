class AddQtsAwardYearStringToStudentLoansEligibilities < ActiveRecord::Migration[8.0]
  def change
    add_column :student_loans_eligibilities, :qts_award_year_string, :string
  end
end
