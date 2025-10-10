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

        if claim.eligibility.provider_verification_continued_employment == false
          create_task
        end
      end

      private

      def create_task
        task = claim.tasks.build(
          {
            name: TASK_NAME,
            claim_verifier_match: nil,
            passed: false,
            manual: false
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
