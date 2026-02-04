module AutomatedChecks
  module ClaimVerifiers
    class ClaimantCheck
      TASK_NAME = "claimant_check".freeze

      def initialize(claim:)
        @claim = claim
      end

      def perform
        return if claim.tasks.exists?(name: TASK_NAME)

        flags = ClaimantFlag.for(claim)

        if flags.any?
          meta_data = flags.map do |flag|
            {
              claimant_match_on: flag.identification_attribute,
              reason: flag.reason,
              suggested_action: flag.suggested_action,
              flag_id: flag.id
            }
          end

          task = claim.tasks.new(
            name: TASK_NAME,
            manual: false,
            passed: nil,
            data: {
              flags: meta_data
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
