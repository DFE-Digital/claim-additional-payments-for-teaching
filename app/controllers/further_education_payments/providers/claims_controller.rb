module FurtherEducationPayments
  module Providers
    class ClaimsController < BaseController
      def index
        @claims = claim_scope.order(
          Arel.sql(
            <<~SQL
              CASE WHEN provider_verification_started_at IS NULL THEN 0 ELSE 1 END,
              claims.created_at ASC
            SQL
          )
        )

        @not_started_count = claim_scope
          .where(further_education_payments_eligibilities: {provider_verification_started_at: nil})
          .count
        @in_progress_count = claim_scope
          .where.not(further_education_payments_eligibilities: {provider_verification_started_at: nil})
          .count
      end

      private

      def claim_scope
        super
          .where(id: Claim.fe_provider_unverified.select(:id))
          .joins(
            <<~SQL
              INNER JOIN further_education_payments_eligibilities
              ON further_education_payments_eligibilities.id = claims.eligibility_id
            SQL
          )
      end
    end
  end
end
