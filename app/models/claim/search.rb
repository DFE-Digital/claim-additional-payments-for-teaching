class Claim
  # Accepts a search term and returns all Claims that match against any of the
  # attributes defined in the `SEARCHABLE_ATTRIBUTES` constant. Both subject
  # and attribute are downcased, so the search is case-insensitive.
  class Search
    attr_accessor :search_term

    SEARCHABLE_ATTRIBUTES = %w[
      reference
      email_address
      surname
      teacher_reference_number
    ]

    def initialize(search_term)
      @search_term = search_term
    end

    def claims
      SEARCHABLE_ATTRIBUTES.inject(Claim.none) do |relation, attribute|
        relation.or(search_by(attribute))
      end
    end

    private

    def search_by(attribute)
      Claim.where("LOWER(#{attribute}) = LOWER(?)", search_term)
    end
  end
end
