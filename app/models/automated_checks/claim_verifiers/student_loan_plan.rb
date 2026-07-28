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
        return unless claim.policy.auto_check_student_loan_plan_task?
        return if task.has_result?

        if student_loans_data.any?
          if claim.student_loan_plan.blank?
            task.assign_attributes(claim_verifier_match: nil, passed: nil, reason: nil)
          else
            task.assign_attributes(claim_verifier_match: :all, passed: true, reason: nil)
          end
        elsif student_loans_data_nino_only.any?
          task.assign_attributes(claim_verifier_match: :none, reason: nil)
        else
          task.assign_attributes(claim_verifier_match: nil, passed: nil, reason: "incomplete")
        end

        ApplicationRecord.transaction do
          task.save!(context: :claim_verifier)
          create_note(match: task.claim_verifier_match)
        end

        task
      end

      private

      attr_accessor :admin_user, :claim

      delegate :national_insurance_number, :date_of_birth, to: :claim
      delegate :student_loan_plan, to: :claim, prefix: :claim
      delegate :repaying_plan_types, to: :student_loans_data, prefix: :slc

      alias_method :nino, :national_insurance_number

      def task
        @task ||= claim.tasks.find_by(name: TASK_NAME) || new_task
      end

      def new_task
        claim.tasks.build(
          name: TASK_NAME,
          manual: false,
          created_by: admin_user
        )
      end

      def student_loans_data
        @student_loans_data ||= StudentLoansData.where(nino:, date_of_birth:)
      end

      def student_loans_data_nino_only
        @student_loans_data_nino_only ||= StudentLoansData.where(nino:).where.not(date_of_birth:)
      end

      def note_body(match:)
        prefix = "[SLC Student loan plan]"
        return "#{prefix} - SLC data checked, no matching entry found" unless match
        return "#{prefix} - No match - DOB does not match" if match == "none"

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
