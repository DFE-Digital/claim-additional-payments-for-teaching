module Policies
  class DuplicateFinder
    def initialize(claim)
      @claim = claim
    end

    def find_approved_claims_in_same_academic_year
      all_matching_claims_subquery =
        Claim::MatchingAttributeFinder.new(claim)
          .matching_claims
          .select(:id)

      Claim
        .by_policy(claim.policy)
        .by_academic_year(claim.academic_year)
        .approved
        .where(id: all_matching_claims_subquery)
    end

    private

    attr_reader :claim
  end
end
