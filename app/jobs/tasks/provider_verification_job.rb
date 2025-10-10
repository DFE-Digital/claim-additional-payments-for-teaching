module Tasks
  class ProviderVerificationJob < ApplicationJob
    def perform(claim)
      task = AutomatedChecks::ClaimVerifiers::ProviderVerification.new(claim:)
      task.perform
    end
  end
end
