class Claim
  # Accepts a search term and returns all Claims that match against any of the
  # attributes defined in the `SEARCHABLE_ATTRIBUTES` or `policy::SEARCHABLE_ELIGIBILITY_ATTRIBUTES` constant. Both subject
  # and attribute are downcased, so the search is case-insensitive.
  class Search
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :search_term, :string
    attribute :current_year_only, :boolean, default: true

    SEARCHABLE_CLAIM_ATTRIBUTES = %w[
      reference
      email_address
      surname
    ]

    def initialize(params)
      super
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

      eligibilities_matched_on_eytfi_provider_details = Policies::EarlyYearsTeachersFinancialIncentivePayments::Eligibility
        .joins("JOIN eligible_eytfi_providers ON eligible_eytfi_providers.urn = early_years_teachers_financial_incentive_payments_eligibilities.eligible_eytfi_provider_urn")
        .where("eligible_eytfi_providers.name ILIKE ?", "%#{search_term}%")

      eligibilities_matched_on_fe_provider_details = Policies::FurtherEducationPayments::Eligibility
        .joins(:school)
        .where("schools.name ILIKE ?", "%#{search_term}%")

      claim_scope = claim_match_query
        .or(Claim.where(eligibility_id: eligibility_ids))
        .or(Claim.where(id: claims_matched_on_payment_ids))
        .or(Claim.where(id: claims_matched_on_ey_provider_details))
        .or(Claim.where(eligibility_id: eligibilities_matched_on_eytfi_provider_details.select(:id)))
        .or(Claim.where(eligibility_id: eligibilities_matched_on_fe_provider_details.select(:id)))

      if current_year_only?
        claim_scope = Claim.current_academic_year.where(id: claim_scope.select(:id))
      end

      claim_scope
    end

    def current_year_only?
      !!current_year_only
    end

    def params
      {
        model_name.param_key => {
          search_term: search_term,
          current_year_only: current_year_only
        }
      }
    end

    private

    def search_by(attribute)
      Claim.where("LOWER(#{attribute}) = LOWER(?)", search_term)
    end
  end
end
