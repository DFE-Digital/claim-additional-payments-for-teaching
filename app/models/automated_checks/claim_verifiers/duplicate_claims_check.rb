module AutomatedChecks
  module ClaimVerifiers
    class DuplicateClaimsCheck
      def initialize(claim:)
        @claim = claim
      end

      def perform
        original_claim = matching_attribute_finder.matching_claims.min_by(&:created_at)

        return unless original_claim
        return if Claims::ClaimDuplicate.exists?(original_claim: original_claim, duplicate_claim: claim)

        Claims::ClaimDuplicate.create!(
          original_claim: original_claim,
          duplicate_claim: claim,
          matching_attributes: matching_attribute_finder.matching_attributes(original_claim)
        )
      end

      private

      attr_reader :claim

      def matching_attribute_finder
        @matching_attribute_finder ||= Claim::MatchingAttributeFinder.new(claim)
      end
    end
  end
end
