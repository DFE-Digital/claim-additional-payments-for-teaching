module Policies
  module FurtherEducationPayments
    class ProviderVerificationEmails
      def initialize(claim)
        @claim = claim
      end

      # First provider email
      def send_further_education_payment_provider_verification_email
        @claim.eligibility.update!(provider_verification_email_last_sent_at: Time.now)
        ClaimMailer.further_education_payment_provider_verification_email(@claim).deliver_later
      end

      # Second automated provider chase email
      def send_further_education_payment_provider_verification_chase_email
        @claim.eligibility.update!(provider_verification_chase_email_last_sent_at: Time.now)
        ClaimMailer.further_education_payment_provider_verification_chase_email(@claim).deliver_later
      end
    end
  end
end
