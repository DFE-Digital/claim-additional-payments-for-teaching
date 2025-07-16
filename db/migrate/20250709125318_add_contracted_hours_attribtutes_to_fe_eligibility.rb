class AddContractedHoursAttribtutesToFeEligibility < ActiveRecord::Migration[8.0]
  def change
    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_teaching_hours_per_week,
      :string
    )

    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_half_teaching_hours,
      :boolean
    )

    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_subjects_taught,
      :boolean
    )

    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_contracted_hours_section_completed,
      :boolean
    )
  end
end
