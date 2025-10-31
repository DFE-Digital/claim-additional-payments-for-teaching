class UpdateTeachingHoursStrings < ActiveRecord::Migration[8.0]
  def change
    Policies::FurtherEducationPayments::Eligibility.where(
      provider_verification_teaching_hours_per_week: "20_or_more_hours_per_week"
    ).update_all(
      provider_verification_teaching_hours_per_week: "more_than_20"
    )

    Policies::FurtherEducationPayments::Eligibility.where(
      provider_verification_teaching_hours_per_week: "12_to_20_hours_per_week"
    ).update_all(
      provider_verification_teaching_hours_per_week: "more_than_12"
    )
  end
end
