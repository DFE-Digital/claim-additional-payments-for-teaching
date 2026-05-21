module AutomatedChecks
  module ClaimVerifiers
    class EyQualificationCheck
      TASK_NAME = "qualifications"

      def initialize(claim:)
        @claim = claim
      end

      def perform
        return if claim.tasks.any? { |task| task.name == TASK_NAME }

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

      attr_reader :claim
    end
  end
end
