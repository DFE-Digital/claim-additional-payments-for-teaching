# frozen_string_literal: true

module Policies
  module InternationalRelocationPayments
    class ClaimCheckingTasks < Policies::ClaimCheckingTasks
      def applicable_task_names
        tasks = []

        tasks << "first_year_application" unless claim.tasks.previous_payment.exists?
        tasks << "previous_payment" if claim.tasks.previous_payment.exists?
        tasks << "identity_confirmation"
        tasks << "visa"
        tasks << "arrival_date" if claim.tasks.arrival_date.exists?
        tasks << "previous_residency" if claim.tasks.previous_residency.exists?
        tasks << "employment"
        tasks << "employment_contract" if task_exists?("employment_contract")
        tasks << "employment_start" if task_exists?("employment_start")
        tasks << "subject" if task_exists?("subject")
        tasks << "teaching_hours"
        tasks << "employment_history" if claim.eligibility.changed_workplace_or_new_contract?
        tasks << "continuous_employment"
        tasks << "payroll_details" if claim.must_manually_validate_bank_details?
        tasks << "matching_details" if matching_claims.exists?
        tasks << "payroll_gender" if claim.payroll_gender_missing? || task_exists?("payroll_gender")

        tasks
      end
    end
  end
end
