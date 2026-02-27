module AutomatedChecks
  module ClaimVerifiers
    class ProviderCheck
      TASK_NAME = "fe_provider_check".freeze

      def initialize(claim:)
        @claim = claim
      end

      def perform
        return if claim.tasks.exists?(name: TASK_NAME)

        flag = Policies::FurtherEducationPayments::ProviderFlag.for(
          claim.eligibility.school.eligible_fe_provider
        )

        if flag
          task = claim.tasks.new(
            name: TASK_NAME,
            manual: false,
            passed: nil,
            data: {
              flag: {
                reason: flag.reason,
                ukprn: flag.ukprn
              }
            }
          )

          task.save!(context: :claim_verifier)
        end
      end

      private

      attr_reader :claim
    end
  end
end
