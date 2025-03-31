module AutomatedChecks
  module ClaimVerifiers
    class StudentLoanPlan
      class MissingClaimPlanError < StandardError
        def initialize(claim)
          super(
            "Claim #{claim.reference} has no student loan plan set. " \
            "but student loan data with matching DOB and NINO was found"
          )
        end
      end

      TASK_NAME = "student_loan_plan".freeze
      private_constant :TASK_NAME

      def initialize(claim:, admin_user: nil)
        self.admin_user = admin_user
        self.claim = claim
      end

      def perform
        return unless claim.policy.auto_check_student_loan_plan_task?
        return unless claim.submitted_without_slc_data?
        return unless awaiting_task?

        student_loan_data_exists || nino_only_match_found || no_student_loan_data_entry
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

      def student_loans_data_nino_only
        @student_loans_data_nino_only ||= StudentLoansData.where(nino:).where.not(date_of_birth:)
      end

      def awaiting_task?
        claim.tasks.where(name: TASK_NAME).count.zero?
      end

      def student_loan_data_exists
        if student_loans_data.any?
          if claim.student_loan_plan.blank?
            raise MissingClaimPlanError.new(claim)
          end

          create_task(match: :all, passed: true)
        end
      end

      def nino_only_match_found
        create_task(match: :none) if student_loans_data_nino_only.any?
      end

      def no_student_loan_data_entry
        create_note(match: nil)
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

      def note_body(match:)
        prefix = "[SLC Student loan plan]"
        return "#{prefix} - SLC data checked, no matching entry found" unless match
        return "#{prefix} - No match - DOB does not match" if match == :none

        if slc_repaying_plan_types
          "#{prefix} - Matched - has a student loan"
        else
          "#{prefix} - Matched - does not have a student loan"
        end
      end

      def create_note(match:)
        claim.notes.create!(
          {
            body: note_body(match:),
            label: TASK_NAME,
            created_by: admin_user
          }
        )
      end
    end
  end
end
