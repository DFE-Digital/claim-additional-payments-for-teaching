class ChangeEarlyCareerPaymentsEligibilitiesPgittOrUgittCourseToQualification < ActiveRecord::Migration[6.0]
  def change
    rename_column :early_career_payments_eligibilities, :pgitt_or_ugitt_course, :qualification
  end
end
