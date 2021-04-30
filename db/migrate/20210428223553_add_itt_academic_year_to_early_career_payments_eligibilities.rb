class AddIttAcademicYearToEarlyCareerPaymentsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :early_career_payments_eligibilities, :itt_academic_year, :integer
  end
end
