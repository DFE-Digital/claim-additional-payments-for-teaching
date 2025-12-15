module Admin
  class EarlyYearsProvidersController < Admin::BaseAdminController
    before_action :ensure_service_operator

    def index
      scope = Policies::EarlyYearsPayments::EligibleEyProvider
        .joins(
          <<~SQL
            LEFT JOIN early_years_payment_eligibilities
              ON early_years_payment_eligibilities.nursery_urn = eligible_ey_providers.urn
            LEFT JOIN claims
              ON claims.eligibility_id = early_years_payment_eligibilities.id
              AND claims.eligibility_type = 'Policies::EarlyYearsPayments::Eligibility'
          SQL
        )
        .where(
          "claims.academic_year = :academic_year OR claims.id IS NULL",
          academic_year: Journeys::EarlyYearsPayment::Provider::Authenticated.configuration.current_academic_year.to_s

        )
        .group(
          "eligible_ey_providers.nursery_name",
          "eligible_ey_providers.primary_key_contact_email_address",
          "eligible_ey_providers.max_claims"
        )
        .select(
          "eligible_ey_providers.nursery_name",
          "eligible_ey_providers.primary_key_contact_email_address",
          "eligible_ey_providers.max_claims",
          "COUNT(claims.id) AS claims_submitted",
          "JSON_AGG(JSON_BUILD_OBJECT('reference', claims.reference, 'id', claims.id)) AS claims_data"
        )

      if params[:query]
        scope = scope.where(
          <<~SQL,
            eligible_ey_providers.nursery_name ILIKE :query
            OR
            eligible_ey_providers.primary_key_contact_email_address ILIKE :query
          SQL
          query: "%#{params[:query]}%"
        )
      end

      scope = scope.order("eligible_ey_providers.nursery_name ASC")

      @provider_results = scope
    end
  end
end
