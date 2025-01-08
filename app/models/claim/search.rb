class Claim
  # Accepts a search term and returns all Claims that match against any of the
  # attributes defined in the `SEARCHABLE_ATTRIBUTES` or `policy::SEARCHABLE_ELIGIBILITY_ATTRIBUTES` constant. Both subject
  # and attribute are downcased, so the search is case-insensitive.
  class Search
    attr_accessor :search_term

    SEARCHABLE_CLAIM_ATTRIBUTES = %w[
      reference
      email_address
      surname
    ]

    def initialize(search_term)
      @search_term = search_term
    end

    def claims
      claim_match_query = SEARCHABLE_CLAIM_ATTRIBUTES.inject(Claim.none) { |relation, attribute|
        relation.or(search_by(attribute))
      }

      eligibility_ids = Policies::POLICIES.map { |policy|
        policy.searchable_eligibility_attributes.map { |attribute|
          policy::Eligibility.where("LOWER(#{attribute}) = LOWER(?)", search_term)
        }
      }.flatten.map(&:id)

      claims_matched_on_payment_ids = Claim.joins(:payments).merge(
        Payment.where(id: search_term)
      )

      claim_match_query
        .or(Claim.where(eligibility_id: eligibility_ids))
        .or(Claim.where(id: claims_matched_on_payment_ids))
    end

    private

    def search_by(attribute)
      Claim.where("LOWER(#{attribute}) = LOWER(?)", search_term)
    end
  end
end
