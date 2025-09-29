class RemoveTimetabledTeachingHoursFromFurtherEducationPaymentsEligibilities < ActiveRecord::Migration[8.0]
  def change
    remove_column :further_education_payments_eligibilities, :teaching_hours_per_week_next_term, :text
    remove_column :further_education_payments_eligibilities, :provider_verification_timetabled_teaching_hours, :boolean
  end
end
