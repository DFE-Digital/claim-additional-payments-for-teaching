module AutomatedChecks
  module ClaimVerifiers
    class StudentLoanPlan
      TASK_NAME = "student_loan_plan".freeze
      private_constant :TASK_NAME

      def initialize(claim:, admin_user: nil)
        self.admin_user = admin_user
        self.claim = claim
      end

      def perform
        return unless claim.has_ecp_or_lupp_policy?
        return unless claim.submitted_without_slc_data?
        return unless awaiting_task?

        no_data || invalid_match || complete_match
      end

      private

      attr_accessor :admin_user, :claim

      delegate :national_insurance_number, :date_of_birth, to: :claim
      delegate :student_loan_plan, to: :claim, prefix: :claim
      delegate :repaying_plan_types, to: :student_loans_data, prefix: :slc

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

      def invalid_match
        return if student_loan_plan_type_exact_match?

        create_task(match: :none, passed: false)
      end

      def complete_match
        return unless student_loan_plan_type_exact_match?

        create_task(match: :all, passed: true)
      end

      def student_loan_plan_type_exact_match?
        claim_student_loan_plan == slc_repaying_plan_types
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
          "[SLC Student loan plan] - No data"
        when :none
          sprintf "[SLC Student loan plan] - The plan type on the claim (%s) didn't match the SLC value (%s)",
            claim_student_loan_plan&.humanize,
            slc_repaying_plan_types&.humanize
        when :all
          "[SLC Student loan plan] - Matched"
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
