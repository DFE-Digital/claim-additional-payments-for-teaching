class AddFeEligibiltyProviderVerificationDeadline < ActiveRecord::Migration[8.1]
  def change
    add_column :further_education_payments_eligibilities,
      :provider_verification_deadline,
      :date,
      null: true
  end
end
