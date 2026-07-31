module AutomatedChecks
  module ClaimVerifiers
    class OneLoginIdentity
      TASK_NAME = "one_login_identity".freeze
      private_constant :TASK_NAME

      def initialize(claim:)
        self.claim = claim
      end

      def perform
        return if task_exists?

        if claim.identity_confirmed_with_onelogin?
          create_task(passed: true)
        else
          create_task(passed: false, reason: "no_data")
        end
      end

      private

      attr_accessor :claim

      def task_exists?
        claim.tasks.where(name: TASK_NAME).exists?
      end

      def create_task(passed:, reason: nil)
        task = claim.tasks.build(
          {
            name: TASK_NAME,
            claim_verifier_match: nil,
            passed: passed,
            manual: false,
            reason:
          }
        )

        task.save!(context: :claim_verifier)

        task
      end
    end
  end
end
