# frozen_string_literal: true

module Policies
  module EarlyYearsPayments
    class ClaimCheckingTasks < Policies::ClaimCheckingTasks
      def applicable_task_names
        persisting_tasks_shim("matching_details")

        tasks = []
        tasks << "ey_eoi_cross_reference" unless year_1_of_ey?
        tasks += identity_task_names
        tasks << "employment"
        tasks << "student_loan_plan" if claim.submitted_without_slc_data?
        tasks << "payroll_details" if claim.must_manually_validate_bank_details?
        tasks << "payroll_gender" if claim.payroll_gender_missing? || task_exists?("payroll_gender")
        tasks << "matching_details" if task_exists?("matching_details")

        tasks
      end

      def identity_status
        if !claim.eligibility.practitioner_journey_completed?
          "Incomplete"
        elsif identity_tasks.any? { |t| t.passed? }
          "Passed"
        elsif identity_tasks.all? { |t| t.failed? }
          "Failed"
        else
          "Unverified"
        end
      end

      private

      def year_1_of_ey?
        claim.academic_year == AcademicYear.new("2024/2025")
      end

      def identity_task_names
        tasks = []

        if year_1_of_ey?
          tasks << if task_exists?("one_login_identity")
            # Handle Y1 claims where practitioner submitted their part after we
            # replaced the Identity claim verifier with the OneLogin verifier.
            "one_login_identity"
          else
            "identity_confirmation"
          end
          tasks << "ey_alternative_verification" if task_exists?("ey_alternative_verification")
        else
          tasks << "one_login_identity"
          tasks << "ey_alternative_verification" if claim.failed_one_login_idv?
        end

        tasks
      end

      def identity_tasks
        identity_task_names.map do |task_name|
          claim.tasks.detect { |t| t.name == task_name } || Task.new
        end
      end
    end
  end
end
