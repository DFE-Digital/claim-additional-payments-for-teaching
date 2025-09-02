module Tasks
  class EyAlternativeVerificationJob < ApplicationJob
    def perform(claim)
      task = AutomatedChecks::ClaimVerifiers::EyAlternativeVerification
        .new(claim:)

      task.perform
    end
  end
end
