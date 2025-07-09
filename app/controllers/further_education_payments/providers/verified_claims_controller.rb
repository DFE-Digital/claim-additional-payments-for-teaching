module FurtherEducationPayments
  module Providers
    class VerifiedClaimsController < BaseController
      def index
        @claims = claim_scope
      end
    end
  end
end
