module AutomatedChecks
  module ClaimVerifiers
    class PreviousYearClaims
      def initialize(claim:)
        @claim = claim
      end

      def perform
        matching_claims.each do |matching_claim|
          Claims::Match.find_or_create_by!(
            source_claim: claim,
            matching_claim: matching_claim
          ) do |match|
            match.matching_attributes = %w[national_insurance_number]
          end
        end
      end

      private

      attr_reader :claim

      def matching_claims
        Claim
          .by_policy(claim.policy)
          .by_academic_year(claim.academic_year.previous)
          .where(national_insurance_number: claim.national_insurance_number)
      end
    end
  end
end
