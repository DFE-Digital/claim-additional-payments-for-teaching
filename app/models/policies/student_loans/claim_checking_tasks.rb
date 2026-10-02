# frozen_string_literal: true

module Policies
  module StudentLoans
    class ClaimCheckingTasks < Policies::ClaimCheckingTasks
      def applicable_task_names
        tasks = []

        tasks << identity_confirmation_task_name
        tasks << "qualifications"
        tasks << "census_subjects_taught"
        tasks << "employment"
        tasks << "student_loan_amount"
        tasks << "payroll_details" if claim.must_manually_validate_bank_details?
        tasks << "matching_details" if task_exists?("matching_details")
        tasks << "payroll_gender" if claim.payroll_gender_missing? || task_exists?("payroll_gender")

        tasks
      end

      private

      def identity_confirmation_task_name
        if claim.eligibility.teacher_auth_completed_at
          "teacher_auth_identity_confirmation"
        else
          "identity_confirmation"
        end
      end

      def identity_confirmation_task
        claim.tasks.detect { |t| t.name == identity_confirmation_task_name }
      end
    end
  end
end
