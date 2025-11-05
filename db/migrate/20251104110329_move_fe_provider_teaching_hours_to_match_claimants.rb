class MoveFeProviderTeachingHoursToMatchClaimants < ActiveRecord::Migration[8.1]
  def change
    Policies::FurtherEducationPayments::Eligibility.where(
      provider_verification_teaching_hours_per_week: "2_and_a_half_to_12_hours_per_week"
    ).update_all(
      provider_verification_teaching_hours_per_week: "between_2_5_and_12"
    )

    Policies::FurtherEducationPayments::Eligibility.where(
      provider_verification_teaching_hours_per_week: "fewer_than_2_and_a_half_hours_per_week"
    ).update_all(
      provider_verification_teaching_hours_per_week: "less_than_2_5"
    )
  end
end
