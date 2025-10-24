module Tasks
  class FeProviderVerificationV2Job < ApplicationJob
    def perform(claim)
      verifier = AutomatedChecks::ClaimVerifiers::ProviderVerificationV2
        .new(claim:)

      verifier.perform
    end
  end
end
