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

      respond_to do |format|
        format.html do
          @provider_results = scope
        end

        format.csv do
          send_data(
            generate_csv(scope),
            filename: "early_years_providers_#{Time.zone.now.strftime("%Y%m%d_%H%M%S")}.csv"
          )
        end
      end
    end

    private

    def generate_csv(provider_results)
      CSV.generate(headers: true) do |csv|
        csv << [
          "Nursery Name",
          "Primary Contact Email",
          "Max Claims",
          "Claims Submitted",
          "Claim References"
        ]

        provider_results.each do |provider|
          claim_references = provider.claims_data.map do |claims_data|
            Array.wrap(claims_data["reference"])
          end.join(" ")

          csv << [
            provider.nursery_name,
            provider.primary_key_contact_email_address,
            provider.max_claims,
            provider.claims_submitted,
            claim_references
          ]
        end
      end
    end
  end
end
