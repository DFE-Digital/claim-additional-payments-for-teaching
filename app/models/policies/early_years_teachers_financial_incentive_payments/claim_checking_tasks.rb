module Policies
  module EarlyYearsTeachersFinancialIncentivePayments
    class ClaimCheckingTasks < Policies::ClaimCheckingTasks
      def applicable_task_names
        tasks = []

        tasks << "identity_confirmation"
        tasks << "qualifications"
        tasks << "employment"
        tasks << "student_loan_plan" if claim.submitted_without_slc_data?
        tasks << "payroll_details" if claim.must_manually_validate_bank_details?
        tasks << "payroll_gender" if claim.payroll_gender_missing? || task_exists?("payroll_gender")
        tasks << "matching_details" if matching_claims.exists?

        tasks
      end
    end
  end
end
