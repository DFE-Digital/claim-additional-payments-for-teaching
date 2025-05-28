module AutomatedChecks
  module ClaimVerifiers
    class PreviousYearClaims
      def initialize(claim:)
        @claim = claim
      end

      def perform
        return unless claim.policy == Policies::InternationalRelocationPayments

        matching_claim_ids = matching_claims.pluck(:id)

        @claim.eligibility.update!(previous_year_claim_ids: matching_claim_ids)
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
