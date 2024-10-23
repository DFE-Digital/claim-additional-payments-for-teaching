module Journeys
  module FurtherEducationPayments
    class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
      def save
        return false unless super

        if Policies::FurtherEducationPayments.duplicate_claim?(claim)
          claim.eligibility.update!(flagged_as_duplicate: true)
        elsif claim.one_login_idv_mismatch?
          # noop
          # do not send provider verification email
        else
          Policies::FurtherEducationPayments::ProviderVerificationEmails.new(claim)
            .send_further_education_payment_provider_verification_email
        end

        true
      end

      private

      def calculate_award_amount(eligibility)
        # NOOP
        # This is just for compatibility with the AdditionalPaymentsForTeaching
        # claim submission form.
      end

      def generate_policy_options_provided
        []
      end
    end
  end
end
