module AutomatedChecks
  module ClaimVerifiers
    class OneLoginIdentity
      TASK_NAME = "one_login_identity".freeze
      private_constant :TASK_NAME

      def initialize(claim:)
        self.claim = claim
      end

      def perform
        return unless awaiting_task?(TASK_NAME)

        if claim.identity_confirmed_with_onelogin?
          create_task(passed: true)
        else
          create_task(passed: false, reason: "no_data")
        end
      end

      private

      attr_accessor :claim

      def awaiting_task?(task_name)
        claim.tasks.none? { |task| task.name == task_name }
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
