module Journeys
  module FurtherEducationPayments
    module Provider
      class SessionAnswers < Journeys::SessionAnswers
        attribute :claim_id, :string
        attribute :declaration, :boolean

        def claim
          @claim ||= Claim.find(claim_id)
        end
      end
    end
  end
end
