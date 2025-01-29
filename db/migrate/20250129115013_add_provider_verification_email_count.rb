class AddProviderVerificationEmailCount < ActiveRecord::Migration[8.0]
  def change
    add_column :further_education_payments_eligibilities, :provider_verification_email_count, :integer, default: 0
  end
end
