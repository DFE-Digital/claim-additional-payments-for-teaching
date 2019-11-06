class Claim
  class MatchingAttributeFinder
    ATTRIBUTES_TO_MATCH = %w[
      teacher_reference_number
      email_address
      national_insurance_number
      bank_account_number
      bank_sort_code
      building_society_roll_number
    ].freeze

    def initialize(source_claim, claims_to_compare = Claim.submitted)
      @source_claim = source_claim
      @claims_to_compare = claims_to_compare
    end

    def matching_claims
      predicates = []
      values = []
      ATTRIBUTES_TO_MATCH.each do |attribute|
        value = @source_claim.read_attribute(attribute)
        next if value.blank?

        predicates << "LOWER(#{attribute}) = LOWER(?)"
        values << value
      end

      @claims_to_compare.where.not(id: @source_claim.id).where(predicates.join(" OR "), *values)
    end
  end
end
