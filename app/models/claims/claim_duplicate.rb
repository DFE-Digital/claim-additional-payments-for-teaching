module Claims
  class ClaimDuplicate < ApplicationRecord
    belongs_to :original_claim, class_name: "Claim"
    belongs_to :duplicate_claim, class_name: "Claim"

    validates :duplicate_claim, uniqueness: {
      scope: :original_claim,
      message: "has already been registered as a duplicate"
    }
    validate :claims_are_not_the_same, if: -> { original_claim && duplicate_claim }
    validate :original_claim_is_older, if: -> { original_claim && duplicate_claim }
    validates :matching_attributes, presence: true

    private

    def claims_are_not_the_same
      return unless original_claim == duplicate_claim

      errors.add(:duplicate_claim, "can't be the same as the original claim")
    end

    def original_claim_is_older
      return unless original_claim.created_at > duplicate_claim.created_at

      errors.add(:original_claim, "must be older than the duplicate claim")
    end
  end
end
