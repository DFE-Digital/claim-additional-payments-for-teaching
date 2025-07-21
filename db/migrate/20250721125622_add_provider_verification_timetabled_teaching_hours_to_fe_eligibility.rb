class AddProviderVerificationTimetabledTeachingHoursToFeEligibility < ActiveRecord::Migration[8.0]
  def change
    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_timetabled_teaching_hours,
      :boolean
    )
  end
end
