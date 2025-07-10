class AddVerificationFieldsToFeEligibility < ActiveRecord::Migration[8.0]
  def change
    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_declaration,
      :boolean
    )

    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_completed_at,
      :timestamp
    )

    add_reference(
      :further_education_payments_eligibilities,
      :provider_verification_verified_by,
      type: :uuid,
      foreign_key: {
        to_table: :dfe_sign_in_users
      },
      null: true
    )
  end
end
