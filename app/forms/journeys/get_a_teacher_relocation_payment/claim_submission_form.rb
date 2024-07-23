module Journeys
  module GetATeacherRelocationPayment
    class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
      private

      def main_eligibility
        @main_eligibility ||= eligibilities.first
      end

      def calculate_award_amount(eligibility)
        eligibility.award_amount = Policies::InternationalRelocationPayments.award_amount
      end

      def generate_policy_options_provided
        []
      end
    end
  end
end
