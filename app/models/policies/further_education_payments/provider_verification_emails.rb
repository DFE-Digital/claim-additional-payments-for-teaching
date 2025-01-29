module Policies
  module FurtherEducationPayments
    class ProviderVerificationEmails
      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end

      # First provider email
      def send_further_education_payment_provider_verification_email
        ApplicationRecord.transaction do
          claim.eligibility.update!(provider_verification_email_last_sent_at: Time.now)
          claim.eligibility.increment!(:provider_verification_email_count)
        end

        ClaimMailer.further_education_payment_provider_verification_email(claim).deliver_later
      end

      # Second and any subsequent automated provider chase email
      def send_further_education_payment_provider_verification_chase_email
        ApplicationRecord.transaction do
          claim.eligibility.update!(provider_verification_email_last_sent_at: Time.now)
          claim.eligibility.increment!(:provider_verification_email_count)
        end

        ClaimMailer.further_education_payment_provider_verification_chase_email(claim).deliver_later
      end
    end
  end
end
