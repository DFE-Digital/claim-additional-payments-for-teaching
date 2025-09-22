module Journeys
  module FurtherEducationPayments
    module Provider
      class SessionForm < Journeys::SessionForm
        attribute :claim_id, :string
      end
    end
  end
end
