module Claims
  class Match < ApplicationRecord
    self.table_name = "claims_matches"

    class NoMatchError < StandardError; end

    belongs_to :left_claim, class_name: "Claim"
    belongs_to :right_claim, class_name: "Claim"

    validate :left_claim_is_older_than_right_claim
    validates :left_claim_id, uniqueness: {scope: :right_claim_id}

    scope :unresolved, -> { where(resolved_at: nil) }

    def self.find_match_record(claim_1, claim_2)
      left_claim, right_claim = sort_for_matching(claim_1, claim_2)

      find_by(left_claim: left_claim, right_claim: right_claim)
    end

    def self.matching_claims(claim)
      Claim.where(id: unresolved.where(left_claim: claim).select(:right_claim_id)).or(
        Claim.where(id: unresolved.where(right_claim: claim).select(:left_claim_id))
      )
    end

    def self.matches(claim)
      unresolved.where(left_claim: claim).or(
        unresolved.where(right_claim: claim)
      )
    end

    def self.sort_for_matching(claim_1, claim_2)
      [claim_1, claim_2].sort_by(&:created_at)
    end

    def self.create_match!(claim_1, claim_2)
      left_claim, right_claim = sort_for_matching(claim_1, claim_2)

      finder = Claim::MatchingAttributeFinder.new(left_claim)

      matching_attributes = finder.matching_attributes(right_claim)

      raise NoMatchError unless matching_attributes.any?

      if (existing_match = find_match_record(left_claim, right_claim))
        existing_match.update!(
          resolved_at: nil,
          matching_attributes: matching_attributes
        )

        match = existing_match
      else
        match = create!(
          left_claim: left_claim,
          right_claim: right_claim,
          matching_attributes: matching_attributes
        )
      end

      match
    end

    def self.update_matching_claims!(claim)
      finder = Claim::MatchingAttributeFinder.new(claim)

      matching_claims = finder.matching_claims

      existing_matches = matching_claims(claim)

      new_matches = matching_claims - existing_matches

      no_longer_matching = existing_matches - matching_claims

      still_matching = existing_matches & matching_claims

      ApplicationRecord.transaction do
        new_matches.each do |matching_claim|
          create_match!(claim, matching_claim)
        end

        still_matching.each do |matching_claim|
          find_match_record(claim, matching_claim).update!(
            matching_attributes: finder.matching_attributes(matching_claim)
          )
        end

        no_longer_matching.each do |non_matching_claim|
          find_match_record(claim, non_matching_claim).update!(
            resolved_at: Time.current
          )
        end

        if claim.persisted?
          claim.update_columns(matching_attributes_last_checked_at: Time.current)
        else
          claim.matching_attributes_last_checked_at = Time.current
        end
      end
    end

    # FIXME once all claims have the matching_attributes_last_checked_at
    # timestamp set delete these two shim methods.
    def self.matching_claims_shim(claim)
      unless claim.matching_attributes_last_checked_at.present?
        update_matching_claims!(claim)
      end

      matching_claims(claim)
    end

    def self.matches_shim(claim)
      unless claim.matching_attributes_last_checked_at.present?
        update_matching_claims!(claim)
      end

      matches(claim)
    end

    def other(claim)
      (left_claim == claim) ? right_claim : left_claim
    end

    def resolved?
      resolved_at.present?
    end

    private

    def left_claim_is_older_than_right_claim
      unless left_claim_is_older_than_right_claim?
        errors.add(:left_claim, "must be created before right_claim")
        errors.add(:right_claim, "must be created after left_claim")
      end
    end

    def left_claim_is_older_than_right_claim?
      left_claim.created_at < right_claim.created_at
    end
  end
end
