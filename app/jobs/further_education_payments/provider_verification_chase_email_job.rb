module FurtherEducationPayments
  class ProviderVerificationChaseEmailJob < CronJob
    CHASE_INTERVALS = {
      1 => 2.weeks,
      2 => 4.weeks
    }.freeze

    self.cron_expression = "0 8 * * *" # Daily 8am

    queue_as :user_data

    def perform
      Rails.logger.info "ProviderVerificationChaseEmailJob sending chase emails..."

      CHASE_INTERVALS.each do |interval|
        batch_for_interval(interval).each do |claim|
          claim.notes.create!(
            label: "provider_verification",
            body: "Verification chaser email sent to #{claim.school.name}"
          )

          Policies::FurtherEducationPayments::ProviderVerificationEmails.new(claim)
            .send_further_education_payment_provider_verification_chase_email
        end
      end
    end

    private

    def batch_for_interval(interval)
      counter, duration = interval

      Policies::FurtherEducationPayments::Eligibility
        .includes(:claim)
        .unverified
        .provider_verification_email_last_sent_over(duration.ago)
        .where(provider_verification_email_count: counter)
        .map(&:claim)
        .reject { |claim| claim.held? || claim.latest_decision&.rejected? }
    end
  end
end
