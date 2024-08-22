module Journeys
  module FurtherEducationPayments
    class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
      def save
        super

        ClaimMailer.further_education_payment_provider_verification_email(claim).deliver_later
      end

      private

      def main_eligibility
        @main_eligibility ||= eligibilities.first
      end

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
