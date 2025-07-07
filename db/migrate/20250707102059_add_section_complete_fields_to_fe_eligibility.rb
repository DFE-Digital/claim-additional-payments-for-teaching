class AddSectionCompleteFieldsToFeEligibility < ActiveRecord::Migration[8.0]
  def change
    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_role_and_experience_section_completed,
      :boolean
    )

    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_contract_covers_section_completed,
      :boolean
    )

    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_taught_one_term_section_completed,
      :boolean
    )
  end
end
