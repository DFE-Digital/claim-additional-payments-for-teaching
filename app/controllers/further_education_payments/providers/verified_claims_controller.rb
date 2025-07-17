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
          .merge(Claim.fe_provider_verified)
          .order(:surname, :first_name)
      end
    end
  end
end
