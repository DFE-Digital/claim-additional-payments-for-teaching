class AddProviderVerificationStartedAtToFurtherEducationPaymentsEligibilities < ActiveRecord::Migration[8.0]
  def change
    add_column :further_education_payments_eligibilities, :provider_verification_started_at, :datetime
  end
end
