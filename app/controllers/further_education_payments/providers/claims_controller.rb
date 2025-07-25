module FurtherEducationPayments
  module Providers
    class ClaimsController < BaseController
      def index
        @claims = claim_scope
        @not_started_count = @claims
          .joins("INNER JOIN further_education_payments_eligibilities ON further_education_payments_eligibilities.id = claims.eligibility_id")
          .where(further_education_payments_eligibilities: {provider_verification_started_at: nil})
          .count
        @in_progress_count = @claims
          .joins("INNER JOIN further_education_payments_eligibilities ON further_education_payments_eligibilities.id = claims.eligibility_id")
          .where.not(further_education_payments_eligibilities: {provider_verification_started_at: nil})
          .count
      end

      private

      def claim_scope
        super.where(id: Claim.fe_provider_unverified.select(:id))
      end
    end
  end
end
