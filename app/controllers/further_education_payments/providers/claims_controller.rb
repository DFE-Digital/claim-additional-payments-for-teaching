module FurtherEducationPayments
  module Providers
    class ClaimsController < BaseController
      def index
        @claims = claim_scope
      end

      private

      def claim_scope
        super.merge(Claim.fe_provider_unverified)
      end
    end
  end
end
