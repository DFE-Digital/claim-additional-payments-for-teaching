module Tasks
  class FeProviderVerificationV2Job < ApplicationJob
    def perform(claim)
      task = AutomatedChecks::ClaimVerifiers::FeProviderVerificationV2
        .new(claim)

      task.perform
    end
  end
end
