module Policies
  module EarlyYearsTeachersFinancialIncentivePayments
    class ClaimCheckingTasks < Policies::ClaimCheckingTasks
      def applicable_task_names
        tasks = []

        tasks << "provider_claim_count" if add_provider_claim_count_task? || task_exists?("provider_claim_count")
        tasks << "one_login_identity"
        tasks << "qualifications"
        tasks << "employment"
        tasks << "student_loan_plan" if claim.submitted_without_slc_data?
        tasks << "payroll_details" if claim.must_manually_validate_bank_details?
        tasks << "payroll_gender" if claim.payroll_gender_missing? || task_exists?("payroll_gender")
        tasks << "matching_details" if task_exists?("matching_details")

        tasks
      end

      def applicable_task_objects
        applicable_task_names.map do |name|
          # The desings call for us to display "Identity confirmation"
          locale_key = (name == "one_login_identity") ? "identity_confirmation" : name
          OpenStruct.new(name:, locale_key:)
        end
      end

      def identity_status
        task = claim.tasks.detect { |t| t.name == "one_login_identity" } || Task.new

        if task.passed?
          "Passed"
        elsif task.failed?
          "Failed"
        else
          "Unverified"
        end
      end

      private

      def add_provider_claim_count_task?
        # Don't add the task to already decided claims
        provider_claim_limit_exceeded? && !claim.decision_made?
      end

      def provider_claim_count
        @provider_claim_count ||= claim
          .eligibility
          .eligible_eytfi_provider
          .claims
          .not_rejected
          .count
      end

      def provider_claim_limit_exceeded?
        return false if claim.eligibility.eligible_eytfi_provider_urn.blank?

        provider_claim_count > claim.eligibility.eligible_eytfi_provider.max_claims
      end
    end
  end
end
