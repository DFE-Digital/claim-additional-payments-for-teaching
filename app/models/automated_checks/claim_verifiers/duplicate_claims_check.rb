module AutomatedChecks
  module ClaimVerifiers
    class DuplicateClaimsCheck
      def initialize(claim:)
        @claim = claim
      end

      def perform
        matching_attribute_finder.matching_claims.each do |existing_claim|
          if existing_claim.created_at < claim.created_at
            original_claim = existing_claim
            duplicate_claim = claim
          else
            original_claim = claim
            duplicate_claim = existing_claim
          end

          unless Claims::ClaimDuplicate.exists?(original_claim: original_claim, duplicate_claim: duplicate_claim)
            Claims::ClaimDuplicate.create!(
              original_claim: original_claim,
              duplicate_claim: duplicate_claim,
              matching_attributes: matching_attribute_finder.matching_attributes(existing_claim)
            )
          end
        end
      end

      private

      attr_reader :claim

      def matching_attribute_finder
        @matching_attribute_finder ||= Claim::MatchingAttributeFinder.new(claim)
      end
    end
  end
end
