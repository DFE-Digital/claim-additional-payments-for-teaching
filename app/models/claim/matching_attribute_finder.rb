class Claim
  class MatchingAttributeFinder
    ATTRIBUTE_GROUPS_TO_MATCH = [
      ["teacher_reference_number"],
      ["email_address"],
      ["national_insurance_number"],
      ["bank_account_number", "bank_sort_code", "building_society_roll_number"]
    ].freeze

    def initialize(source_claim)
      @source_claim = source_claim
    end

    # Returns a list of claims that could potentially be from the same applicant
    # because they either share a same single attribute with the source claim,
    # (for example, the same TRN, or email), or they share a group of attributes
    # with the source claim (for example bank sort code, account number and roll
    # number).
    #
    # This may not necessarily mean the claim cannot be approved, but means it
    # warrants a degree of caution and further investigation.
    def matching_claims
      match_queries = nil

      ATTRIBUTE_GROUPS_TO_MATCH.each do |attributes|
        vals = values_for_attributes(attributes)

        next if vals.blank?

        concatenated_columns = "CONCAT(#{attributes.join(",")})"
        query = Claim.where("LOWER(#{concatenated_columns}) = LOWER(?)", vals.join)

        match_queries = match_queries.nil? ? query : match_queries.or(query)
      end

      claims_to_compare.merge(match_queries)
    end

    private

    def claims_to_compare
      Claim.submitted
        .by_policy(@source_claim.policy)
        .by_academic_year(@source_claim.academic_year)
        .where.not(id: @source_claim.id)
    end

    def values_for_attributes(attributes)
      attributes.map { |attribute|
        @source_claim.read_attribute(attribute)
      }.reject(&:blank?)
    end
  end
end
