class AddPgittOrUgittCourseToEarlyCareerPaymentsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :early_career_payments_eligibilities, :pgitt_or_ugitt_course, :integer
  end
end
