module Journeys
  module TeacherStudentLoanReimbursement
    class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
      private

      def main_eligibility
        @main_eligibility ||= eligibilities.first
      end

      def calculate_award_amount(eligibility)
        # NOOP
      end

      def generate_policy_options_provided
        []
      end
    end
  end
end
