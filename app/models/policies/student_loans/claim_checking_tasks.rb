# frozen_string_literal: true

module Policies
  module StudentLoans
    class ClaimCheckingTasks < Policies::ClaimCheckingTasks
      def applicable_task_names
        persisting_tasks_shim("matching_details")

        tasks = []

        tasks << "identity_confirmation"
        tasks << "qualifications"
        tasks << "census_subjects_taught"
        tasks << "employment"
        tasks << "student_loan_amount"
        tasks << "payroll_details" if claim.must_manually_validate_bank_details?
        tasks << "matching_details" if FeatureFlag.enabled?(:persist_matching_claims) ? task_exists?("matching_details") : matching_claims.exists?
        tasks << "payroll_gender" if claim.payroll_gender_missing? || task_exists?("payroll_gender")

        tasks
      end
    end
  end
end
