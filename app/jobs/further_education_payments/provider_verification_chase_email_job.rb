module FurtherEducationPayments
  class ProviderVerificationChaseEmailJob < ApplicationJob
    queue_as :user_data

    def perform
      Rails.logger.info "ProviderVerificationChaseEmailJob sending chase emails..."

      unverified_claims_with_provider_email_sent_over_3_weeks_ago.each do |claim|
        claim.notes.create!(
          label: "provider_verification",
          body: "Verification chaser email sent to #{claim.school.name}"
        )

        Policies::FurtherEducationPayments::ProviderVerificationEmails.new(claim)
          .send_further_education_payment_provider_verification_chase_email
      end
    end

    private

    def unverified_claims_with_provider_email_sent_over_3_weeks_ago
      Policies::FurtherEducationPayments::Eligibility
        .includes(:claim)
        .unverified
        .provider_verification_email_last_sent_over(3.weeks.ago)
        .provider_verification_chase_email_not_sent
        .map(&:claim)
        .reject { |claim| claim.held? || claim.latest_decision&.rejected? }
    end
  end
end
