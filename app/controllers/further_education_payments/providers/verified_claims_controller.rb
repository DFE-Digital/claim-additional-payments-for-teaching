module FurtherEducationPayments
  module Providers
    class VerifiedClaimsController < BaseController
      def index
        @claims = claim_scope
      end

      private

      def claim_scope
        super.merge(Claim.fe_provider_verified)
      end
    end
  end
end
