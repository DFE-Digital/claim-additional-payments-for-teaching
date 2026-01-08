# Removes attributes from a claim and its amendments
class Claim
  class Scrubber
    def self.scrub!(claim, attributes_to_delete)
      new(claim, attributes_to_delete).scrub!
    end

    attr_reader :claim, :attributes_to_delete

    def initialize(claim, attributes_to_delete)
      @claim = claim
      @attributes_to_delete = attributes_to_delete.map(&:to_s)
    end

    def scrub!
      ApplicationRecord.transaction do
        claim.amendments.each { |amendment| scrub_amendment!(amendment) }
        scrub_claim!
        scrub_eligibility!
        scrub_session!
      end
    end

    private

    def scrub_amendment!(amendment)
      amendment_data_to_scrub = attributes_to_delete & amendment.claim_changes.keys.map(&:to_s)
      personal_data_mask = amendment_data_to_scrub.to_h { |attr| [attr, nil] }
      amendment.claim_changes.merge!(personal_data_mask)
      amendment.personal_data_removed_at = Time.zone.now
      amendment.save!
    end

    def scrub_claim!
      attributes_to_scrub = attributes_to_delete & claim.attribute_names
      personal_data_mask = attributes_to_scrub.to_h { |attr| [attr, nil] }
      attributes_to_set = personal_data_mask.merge(
        personal_data_removed_at: Time.zone.now
      )
      claim.update!(attributes_to_set)
      Claims::Match.update_matching_claims!(claim)
    end

    def scrub_eligibility!
      attributes_to_scrub = attributes_to_delete & claim.eligibility.attribute_names
      attributes_to_set = attributes_to_scrub.to_h { |attr| [attr, nil] }
      claim.eligibility.update!(attributes_to_set)
    end

    def scrub_session!
      return unless claim.journey_session

      claim.journey_session.update!(answers: {})
    end
  end
end
