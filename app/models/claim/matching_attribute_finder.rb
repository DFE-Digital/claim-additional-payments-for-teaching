class Claim
  class MatchingAttributeFinder
    # Fields on the claim model to consider a match
    CLAIM_ATTRIBUTE_GROUPS_TO_MATCH = [
      ["email_address"],
      ["national_insurance_number"],
      ["bank_account_number", "bank_sort_code", "building_society_roll_number"],
      ["first_name", "surname", "date_of_birth"]
    ].freeze

    def initialize(source_claim)
      @source_claim = source_claim
    end

    # Returns a list of claims that could potentially be from the same applicant
    # because they either share a same single attribute with the source claim,
    # (for example, the same national_insurance_number, email, etc...), or they share a group of attributes
    # with the source claim (for example bank sort code, account number and roll
    # number).
    #
    # The associated eligibility fields can be used as well
    #
    # This may not necessarily mean the claim cannot be approved, but means it
    # warrants a degree of caution and further investigation.
    def matching_claims
      match_queries = Claim.none

      # Claim attributes
      CLAIM_ATTRIBUTE_GROUPS_TO_MATCH.each do |attributes|
        vals = values_for_attributes(@source_claim, attributes)
        next if vals.blank?

        concatenated_columns = "CONCAT(#{attributes.join(",")})"
        query = Claim.where("LOWER(#{concatenated_columns}) = LOWER(?)", vals.join)

        match_queries = match_queries.or(query)
      end

      # Eligibility attributes
      eligibility_ids = eligibility_attributes_groups_to_match.map { |attributes|
        vals = values_for_attributes(@source_claim.eligibility, attributes)
        next if vals.blank?

        concatenated_columns = "CONCAT(#{attributes.join(",")})"
        policies_to_find_matches.map { |policy|
          policy::Eligibility.where("LOWER(#{concatenated_columns}) = LOWER(?)", vals.join) if (attributes - policy::Eligibility.column_names).empty?
        }
      }.flatten.compact.map(&:id)

      eligibility_match_query = Claim.where(eligibility_id: eligibility_ids)
      match_queries = match_queries.or(eligibility_match_query)

      claims_to_compare.merge(match_queries)
    end

    def matching_attributes(other_claim)
      matching_claim_attributes = CLAIM_ATTRIBUTE_GROUPS_TO_MATCH.select do |attributes|
        values_for_attributes(@source_claim, attributes) == values_for_attributes(other_claim, attributes)
      end

      matching_eligibility_attributes = eligibility_attributes_groups_to_match.select do |attributes|
        values_for_attributes(@source_claim.eligibility, attributes) == values_for_attributes(other_claim.eligibility, attributes)
      end

      (matching_claim_attributes + matching_eligibility_attributes).flatten
    end

    private

    def policies_to_find_matches
      @source_claim.policy.policies_claimable
    end

    def eligibility_attributes_groups_to_match
      @source_claim.policy.eligibility_matching_attributes
    end

    def policies_to_find_matches_eligibility_types
      policies_to_find_matches.map { |policy| policy::Eligibility.to_s }
    end

    def claims_to_compare
      Claim
        .by_academic_year(@source_claim.academic_year)
        .by_policies(policies_to_find_matches)
        .where.not(id: @source_claim.id)
    end

    def values_for_attributes(object, attributes)
      attributes.map { |attribute|
        object.read_attribute(attribute)
      }.reject(&:blank?)
    end
  end
end
