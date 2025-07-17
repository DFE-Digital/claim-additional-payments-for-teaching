class RemoveProgressTrackingColumnsFromFeEligibility < ActiveRecord::Migration[8.0]
  def change
    remove_column(
      :further_education_payments_eligibilities,
      :provider_verification_role_and_experience_section_completed,
      :boolean
    )

    remove_column(
      :further_education_payments_eligibilities,
      :provider_verification_contract_covers_section_completed,
      :boolean
    )

    remove_column(
      :further_education_payments_eligibilities,
      :provider_verification_taught_one_term_section_completed,
      :boolean
    )

    remove_column(
      :further_education_payments_eligibilities,
      :provider_verification_performance_section_completed,
      :boolean
    )

    remove_column(
      :further_education_payments_eligibilities,
      :provider_verification_contracted_hours_section_completed,
      :boolean
    )
  end
end
