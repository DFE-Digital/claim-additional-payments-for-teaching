module Journeys
  module TeacherStudentLoanReimbursement
    class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
      private

      def calculate_award_amount(eligibility)
        # NOOP
      end

      def generate_policy_options_provided
        []
      end
    end
  end
end
