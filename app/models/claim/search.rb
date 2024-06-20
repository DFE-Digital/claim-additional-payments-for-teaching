class Claim
  # Accepts a search term and returns all Claims that match against any of the
  # attributes defined in the `SEARCHABLE_ATTRIBUTES` or `SEARCHABLE_ELIGIBILITY_ATTRIBUTES` constant. Both subject
  # and attribute are downcased, so the search is case-insensitive.
  class Search
    attr_accessor :search_term

    POLICIES = [
      Policies::StudentLoans,
      Policies::EarlyCareerPayments,
      Policies::LevellingUpPremiumPayments
    ]

    SEARCHABLE_CLAIM_ATTRIBUTES = %w[
      reference
      email_address
      surname
    ]

    SEARCHABLE_ELIGIBILITY_ATTRIBUTES = %w[
      teacher_reference_number
    ]

    def initialize(search_term)
      @search_term = search_term
    end

    def claims
      claim_match_query = SEARCHABLE_CLAIM_ATTRIBUTES.inject(Claim.none) { |relation, attribute|
        relation.or(search_by(attribute))
      }

      eligibility_ids = SEARCHABLE_ELIGIBILITY_ATTRIBUTES.map { |attribute|
        POLICIES.map { |policy|
          policy::Eligibility.where("LOWER(#{attribute}) = LOWER(?)", search_term)
        }
      }.flatten.map(&:id)

      claim_match_query.or(Claim.where(eligibility_id: eligibility_ids))
    end

    private

    def search_by(attribute)
      Claim.submitted.where("LOWER(#{attribute}) = LOWER(?)", search_term)
    end
  end
end
