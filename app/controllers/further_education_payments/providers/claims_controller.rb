module FurtherEducationPayments
  module Providers
    class ClaimsController < BaseController
      def index
        @claims = claim_scope
      end

      private

      def claim_scope
        super.where(id: Claim.fe_provider_unverified.select(:id))
      end
    end
  end
end
