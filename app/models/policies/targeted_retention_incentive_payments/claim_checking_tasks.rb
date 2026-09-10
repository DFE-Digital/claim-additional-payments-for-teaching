# frozen_string_literal: true

module Policies
  module TargetedRetentionIncentivePayments
    class ClaimCheckingTasks < Policies::ClaimCheckingTasks
      def applicable_task_names
        if claim.academic_year <= AcademicYear.new("2025")
          task_names_2025_2026_and_before
        else
          task_names_pre_2026_2027_and_after
        end
      end

      private

      def task_names_2025_2026_and_before
        tasks = []

        tasks << "identity_confirmation"
        tasks << "qualifications"
        tasks << "census_subjects_taught"
        tasks << "employment"
        tasks << "student_loan_plan" if claim.submitted_without_slc_data?
        tasks << "payroll_details" if claim.must_manually_validate_bank_details?
        tasks << "matching_details" if task_exists?("matching_details")
        tasks << "payroll_gender" if claim.payroll_gender_missing? || task_exists?("payroll_gender")

        tasks
      end

      def task_names_pre_2026_2027_and_after
        claim.tasks.map(&:name)
      end
    end
  end
end
