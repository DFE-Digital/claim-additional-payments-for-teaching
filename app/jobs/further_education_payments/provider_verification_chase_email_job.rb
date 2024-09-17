module FurtherEducationPayments
  class ProviderVerificationChaseEmailJob < CronJob
    # Daily 8am
    self.cron_expression = "0 8 * * *"

    queue_as :user_data

    def perform
      Rails.logger.info "ProviderVerificationChaseEmailJob sending chase emails..."

      unverified_claims_with_provider_email_sent_over_3_weeks_ago.each do |claim|
        Policies::FurtherEducationPayments::ProviderVerificationEmails.new(claim)
          .send_further_education_payment_provider_verification_chase_email
      end
    end

    private

    def unverified_claims_with_provider_email_sent_over_3_weeks_ago
      Policies::FurtherEducationPayments::Eligibility
        .includes(:claim)
        .unverified
        .where("provider_verification_email_last_sent_at < ?", 3.weeks.ago)
        .map(&:claim)
    end
  end
end
