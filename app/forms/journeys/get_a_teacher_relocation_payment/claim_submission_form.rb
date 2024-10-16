module Journeys
  module GetATeacherRelocationPayment
    class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
      private

      def calculate_award_amount(eligibility)
        eligibility.award_amount = Policies::InternationalRelocationPayments.award_amount
      end

      def generate_policy_options_provided
        []
      end
    end
  end
end
