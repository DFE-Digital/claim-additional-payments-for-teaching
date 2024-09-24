class AddProviderVerificationChaseEmailLastSentAtToFurtherEducationPaymentsEligibilities < ActiveRecord::Migration[7.0]
  def change
    add_column :further_education_payments_eligibilities, :provider_verification_chase_email_last_sent_at, :datetime
  end
end
