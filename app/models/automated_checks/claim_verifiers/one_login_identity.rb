module AutomatedChecks
  module ClaimVerifiers
    class OneLoginIdentity
      TASK_NAME = "one_login_identity".freeze
      private_constant :TASK_NAME

      def initialize(claim:, admin_user: nil)
        self.admin_user = admin_user
        self.claim = claim
      end

      def perform
        return unless awaiting_task?(TASK_NAME)

        if !claim.identity_confirmed_with_onelogin?
          create_task(passed: false)
        elsif claim.one_login_idv_mismatch?
          create_task(passed: false)
        else
          create_task(passed: true)
        end
      end

      private

      attr_accessor :admin_user, :claim

      def awaiting_task?(task_name)
        claim.tasks.none? { |task| task.name == task_name }
      end

      def create_task(passed:)
        task = claim.tasks.build(
          {
            name: TASK_NAME,
            claim_verifier_match: nil,
            passed: passed,
            manual: false,
            created_by: admin_user
          }
        )

        task.save!(context: :claim_verifier)

        task
      end
    end
  end
end
