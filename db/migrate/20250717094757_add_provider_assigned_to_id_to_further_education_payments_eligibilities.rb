class AddProviderAssignedToIdToFurtherEducationPaymentsEligibilities < ActiveRecord::Migration[8.0]
  def change
    add_reference(
      :further_education_payments_eligibilities,
      :provider_assigned_to,
      type: :uuid,
      foreign_key: {
        to_table: :dfe_sign_in_users
      },
      null: true
    )
  end
end
