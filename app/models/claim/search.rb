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

      claims_matched_on_ey_provider_details = Claim
        .joins(:early_years_payment_eligibility)
        .joins("JOIN eligible_ey_providers ON eligible_ey_providers.urn = early_years_payment_eligibilities.nursery_urn")
        .where(
          <<~SQL, search_term: search_term
            LOWER(claims.practitioner_email_address) = LOWER(:search_term)
            OR LOWER(early_years_payment_eligibilities.provider_email_address) = LOWER(:search_term)
            OR LOWER(eligible_ey_providers.nursery_name) = LOWER(:search_term)
            OR LOWER(eligible_ey_providers.primary_key_contact_email_address) = LOWER(:search_term)
            OR LOWER(eligible_ey_providers.secondary_contact_email_address) = LOWER(:search_term)
          SQL
        )

      claim_match_query
        .or(Claim.where(eligibility_id: eligibility_ids))
        .or(Claim.where(id: claims_matched_on_payment_ids))
        .or(Claim.where(id: claims_matched_on_ey_provider_details))
    end

    private

    def search_by(attribute)
      Claim.where("LOWER(#{attribute}) = LOWER(?)", search_term)
    end
  end
end
