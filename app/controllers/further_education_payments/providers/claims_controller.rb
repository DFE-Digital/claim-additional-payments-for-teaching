module FurtherEducationPayments
  module Providers
    class ClaimsController < BaseController
      def index
        @claims = claim_scope
        @not_started_count = @claims.joins(:eligibility).where(eligibility: {provider_verification_started_at: nil}).count
        @in_progress_count = @claims.joins(:eligibility).where.not(eligibility: {provider_verification_started_at: nil}).count
      end

      private

      def claim_scope
        super.where(id: Claim.fe_provider_unverified.select(:id))
      end
    end
  end
end
