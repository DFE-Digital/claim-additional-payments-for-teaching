module AutomatedChecks
  module ClaimVerifiers
    class FeProviderVerificationV2
      TASK_NAME = "fe_provider_verification_v2".freeze

      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end

      def perform
        return if task_already_persisted?

        failed_checks = []

        if claim.eligibility.provider_verification_continued_employment == false
          failed_checks << "no_continued_employment"
        end

        unless claim.eligibility.valid_reason_for_not_starting_qualification?
          failed_checks << "no_valid_reason_for_not_starting_qualification"
        end

        if claim.eligibility.insufficient_teaching_hours_per_week?
          failed_checks << "insufficient_teaching_hours_per_week"
        end

        if claim.eligibility.teaching_hours_mismatch?
          failed_checks << "mismatch_in_teaching_hours"
        end

        create_task(failed_checks) if failed_checks.any?
      end

      private

      def create_task(failed_checks)
        task = claim.tasks.build(
          {
            name: TASK_NAME,
            claim_verifier_match: nil,
            passed: false,
            manual: false,
            data: {
              failed_checks: failed_checks
            }
          }
        )

        task.save!(context: :claim_verifier)

        task
      end

      def task_already_persisted?
        claim.tasks.any? { |task| task.name == TASK_NAME }
      end
    end
  end
end
