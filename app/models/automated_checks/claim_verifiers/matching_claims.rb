module AutomatedChecks
  module ClaimVerifiers
    class MatchingClaims
      def initialize(claim:)
        @claim = claim
      end

      def perform
        Claims::Match.update_matching_claims!(claim)
      end

      private

      attr_reader :claim
    end
  end
end
