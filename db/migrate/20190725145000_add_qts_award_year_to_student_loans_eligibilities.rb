class AddQtsAwardYearToStudentLoansEligibilities < ActiveRecord::Migration[5.2]
  def change
    add_column :student_loans_eligibilities, :qts_award_year, :integer
  end
end
