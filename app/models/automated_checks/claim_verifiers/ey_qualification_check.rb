module AutomatedChecks
  module ClaimVerifiers
    class EyQualificationCheck
      TASK_NAME = "qualifications"

      def initialize(claim:)
        @claim = claim
      end

      def perform
        return if task_exists?

        # Task always passes as only those with the expected teacher status can
        # complete the journey.
        task = claim.tasks.build(
          name: TASK_NAME,
          passed: true,
          manual: false
        )

        task.save!(context: :claim_verifier)
      end

      private

      def task_exists?
        claim.tasks.where(name: TASK_NAME).exists?
      end

      attr_reader :claim
    end
  end
end
