class AddStringEnumColumnsToPoliciesStudentLoansEligibilities < ActiveRecord::Migration[8.0]
  def change
    add_column :student_loans_eligibilities, :qts_award_year_string, :string
    add_column :student_loans_eligibilities, :employment_status_string, :string
  end
end
