module Tasks
  class FeAlternativeVerificationJob < ApplicationJob
    def perform(claim)
      task = AutomatedChecks::ClaimVerifiers::FeAlternativeVerification
        .new(claim:)

      task.perform
    end
  end
end
