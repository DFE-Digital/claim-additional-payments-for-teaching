module Journeys
  module FurtherEducationPayments
    class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
      def save
        super

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

      def main_eligibility
        @main_eligibility ||= eligibilities.first
      end

      def calculate_award_amount(claim)
        claim.award_amount = answers.award_amount
      end

      def generate_policy_options_provided
        []
      end
    end
  end
end
