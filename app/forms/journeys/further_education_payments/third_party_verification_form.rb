module Journeys
  module FurtherEducationPayments
    class ThirdPartyVerificationForm
      include ActiveModel::Model

      def initialize(claim:, params:)
        @claim = claim

        # super(permitted_params(params)) # permitting params TBD
        super()
      end

      def save
        # ...
      end
    end
  end
end
