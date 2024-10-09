module Journeys
  module TeacherStudentLoanReimbursement
    class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
      private

      def main_eligibility
        @main_eligibility ||= eligibilities.first
      end

      # Award amount is the student loan repayment amount set by a job
      def calculate_award_amount(claim)
        claim.award_amount = answers.student_loan_repayment_amount
      end

      def generate_policy_options_provided
        []
      end
    end
  end
end
