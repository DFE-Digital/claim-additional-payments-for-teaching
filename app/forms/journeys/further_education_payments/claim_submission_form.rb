module Journeys
  module FurtherEducationPayments
    class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
      private

      def main_eligibility
        @main_eligibility ||= Policies::FurtherEducationPayments::Eligibility.new
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
