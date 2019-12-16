class Claim
  class MatchingAttributeFinder
    ATTRIBUTE_GROUPS_TO_MATCH = [
      ["teacher_reference_number"],
      ["email_address"],
      ["national_insurance_number"],
      ["bank_account_number", "bank_sort_code", "building_society_roll_number"],
    ].freeze

    def initialize(source_claim, claims_to_compare = Claim.submitted)
      @source_claim = source_claim
      @claims_to_compare = claims_to_compare
    end

    def matching_claims
      claims = @claims_to_compare.where.not(id: @source_claim.id)
      match_queries = nil

      ATTRIBUTE_GROUPS_TO_MATCH.each do |attributes|
        vals = values_for_attributes(attributes)

        next if vals.blank?

        concatenated_columns = "CONCAT(#{attributes.join(",")})"
        query = Claim.where("LOWER(#{concatenated_columns}) = LOWER(?)", vals.join)

        match_queries = match_queries.nil? ? query : match_queries.or(query)
      end

      claims.merge(match_queries)
    end

    private

    def values_for_attributes(attributes)
      attributes.map { |attribute|
        @source_claim.read_attribute(attribute)
      }.reject(&:blank?)
    end
  end
end
