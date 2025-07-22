class AddPvHalfTimetabledTeachingTime < ActiveRecord::Migration[8.0]
  def change
    add_column :further_education_payments_eligibilities,
      :provider_verification_half_timetabled_teaching_time,
      :boolean
  end
end
