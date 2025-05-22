module Claims
  class Match < ApplicationRecord
    belongs_to :source_claim, class_name: "Claim"
    belongs_to :matching_claim, class_name: "Claim"

    validate :match_is_from_previous_year

    private

    def match_is_from_previous_year
      unless match_is_from_previous_year?
        errors.add(:matching_claim, "must be from the previous academic year")
      end
    end

    def match_is_from_previous_year?
      (source_claim.academic_year - 1) == matching_claim.academic_year
    end
  end
end
