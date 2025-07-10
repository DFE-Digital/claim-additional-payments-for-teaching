class AddPerformanceAttributesToFeEligibility < ActiveRecord::Migration[8.0]
  def change
    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_performance_measures,
      :boolean
    )

    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_disciplinary_action,
      :boolean
    )

    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_performance_section_completed,
      :boolean
    )
  end
end
