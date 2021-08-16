class ChangeEarlyCareerPaymentsEligibilitiesIttAcademicYearFromIntegerToString < ActiveRecord::Migration[6.0]
  def change
    change_column :early_career_payments_eligibilities, :itt_academic_year, :string, limit: 9
  end
end
