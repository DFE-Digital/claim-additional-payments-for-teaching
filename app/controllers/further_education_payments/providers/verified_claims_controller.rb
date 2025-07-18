module FurtherEducationPayments
  module Providers
    class VerifiedClaimsController < BaseController
      def index
        @all_claims = claim_scope
        @pagy, @claims = pagy(claim_scope)
      end

      private

      def claim_scope
        super
          .where(id: Claim.fe_provider_verified.select(:id))
          .order(:surname, :first_name)
      end
    end
  end
end
