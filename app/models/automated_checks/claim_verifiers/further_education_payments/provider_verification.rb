module AutomatedChecks
  module ClaimVerifiers
    module FurtherEducationPayments
      class ProviderVerification
        TASK_NAME = "fe_provider_verification_v2"

        def initialize(claim:)
          @claim = claim
        end

        def perform
          return if @claim.tasks.exists?(name: TASK_NAME)

          unless @claim.eligibility.valid_reason_for_not_starting_qualification?
            @claim.tasks.create!(
              name: TASK_NAME,
              passed: false,
              manual: false
            )
          end
        end
      end
    end
  end
end
