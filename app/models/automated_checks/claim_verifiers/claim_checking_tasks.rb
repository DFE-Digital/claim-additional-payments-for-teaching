module AutomatedChecks
  module ClaimVerifiers
    class ClaimCheckingTasks
      attr_reader :claim

      def initialize(claim:)
        @claim = claim
      end

      def perform
        claim_checking_tasks = claim.policy::ClaimCheckingTasks.new(claim)

        task_list = claim_checking_tasks.applicable_task_names

        claim.update!(task_list: task_list)
      end
    end
  end
end
