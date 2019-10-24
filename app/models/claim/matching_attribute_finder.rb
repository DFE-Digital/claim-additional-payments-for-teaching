class Claim
  class MatchingAttributeFinder
    ATTRIBUTES_TO_MATCH = [
      "teacher_reference_number",
      "email_address",
      "national_insurance_number",
      "bank_account_number",
      "bank_sort_code",
      "building_society_roll_number",
    ].freeze

    def initialize(claim, relation = Claim.all)
      @claim = claim
      @relation = relation
    end

    def claim_ids_with_matching_attributes
      duplicates.map { |claim_with_matching_attributes|
        [claim_with_matching_attributes.id, matching_attributes(claim_with_matching_attributes)]
      }.to_h
    end

    private

    def duplicates
      @relation.where(teacher_reference_number: @claim.teacher_reference_number)
        .or(@relation.where(national_insurance_number: @claim.national_insurance_number))
        .or(@relation.where(email_address: @claim.email_address))
        .or(@relation.where(bank_account_number: @claim.bank_account_number))
        .or(@relation.where(bank_sort_code: @claim.bank_sort_code))
        .or(@relation.where(building_society_roll_number: @claim.building_society_roll_number))
        .where.not(id: @claim.id)
    end

    def matching_attributes(claim)
      matching_attributes = @claim.attributes.slice(*ATTRIBUTES_TO_MATCH).to_a & claim.attributes.slice(*ATTRIBUTES_TO_MATCH).to_a
      matching_attributes.to_h.keys.map(&:humanize)
    end
  end
end
