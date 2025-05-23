module AutomatedChecks
  module ClaimVerifiers
    class StudentLoanAmount
      TASK_NAME = "student_loan_amount".freeze
      private_constant :TASK_NAME

      def initialize(claim:, admin_user: nil)
        self.admin_user = admin_user
        self.claim = claim
      end

      def perform
        return unless claim.policy == Policies::StudentLoans
        return unless awaiting_task?

        no_data || no_match || invalid_match || complete_match
      end

      private

      attr_accessor :admin_user, :claim

      delegate :national_insurance_number, :date_of_birth, :eligibility, to: :claim
      delegate :student_loan_plan, to: :claim, prefix: :claim
      delegate :award_amount, to: :eligibility, prefix: :claim
      delegate :repaying_plan_types, :total_repayment_amount, to: :student_loans_data, prefix: :slc

      alias_method :nino, :national_insurance_number

      def student_loans_data
        @student_loans_data ||= StudentLoansData.where(nino:, date_of_birth:)
      end

      def awaiting_task?
        claim.tasks.where(name: TASK_NAME).count.zero?
      end

      def no_data
        return if student_loans_data.any?

        create_task(match: nil)
      end

      def no_match
        return unless slc_total_repayment_amount&.zero?

        create_task(match: :none)
      end

      def invalid_match
        return unless student_loan_repayment_amount_greater_than_actual?

        create_task(match: :none, passed: false)
      end

      def complete_match
        return unless amount_and_plan_type_valid?

        create_task(match: :all, passed: true)
      end

      def student_loan_repayment_amount_greater_than_actual?
        claim_award_amount > slc_total_repayment_amount
      end

      def student_loan_repayment_amount_less_than_or_equal_to_actual?
        claim_award_amount <= slc_total_repayment_amount
      end

      def student_loan_plan_type_exact_match?
        claim_student_loan_plan == slc_repaying_plan_types
      end

      def amount_and_plan_type_valid?
        student_loan_repayment_amount_less_than_or_equal_to_actual? && student_loan_plan_type_exact_match?
      end

      def create_task(match:, passed: nil)
        task = claim.tasks.build(
          {
            name: TASK_NAME,
            claim_verifier_match: match,
            passed: passed,
            manual: false,
            created_by: admin_user
          }
        )

        task.save!(context: :claim_verifier)

        create_note(match: match)

        task
      end

      def create_note(match:)
        body = case match
        when nil
          "[SLC Student loan amount] - No data"
        when :none
          if slc_total_repayment_amount&.zero?
            "[SLC Student loan amount] - The total SLC repayment amount is £0"
          elsif student_loan_repayment_amount_greater_than_actual?
            sprintf "[SLC Student loan amount] - The amount on the claim (%.2f) exceeded the SLC value (%.2f)",
              claim_award_amount,
              slc_total_repayment_amount
          end
        when :all
          "[SLC Student loan amount] - Matched"
        end

        claim.notes.create!(
          {
            body: body,
            label: TASK_NAME,
            created_by: admin_user
          }
        )
      end
    end
  end
end
