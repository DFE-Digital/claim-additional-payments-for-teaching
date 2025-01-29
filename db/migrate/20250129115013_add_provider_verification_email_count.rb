class AddProviderVerificationEmailCount < ActiveRecord::Migration[8.0]
  def change
    add_column :further_education_payments_eligibilities, :provider_verification_email_count, :integer, default: 0

    Policies::FurtherEducationPayments::Eligibility
      .where("provider_verification_email_last_sent_at IS NOT NULL")
      .where("provider_verification_chase_email_last_sent_at IS NULL")
      .update_all(provider_verification_email_count: 1)

    Policies::FurtherEducationPayments::Eligibility
      .where("provider_verification_chase_email_last_sent_at IS NOT NULL")
      .update_all(provider_verification_email_count: 2)
  end
end
