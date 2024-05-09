module Journeys
  class Session < ApplicationRecord
    has_one :claim,
      dependent: :nullify,
      inverse_of: :journeys_session,
      foreign_key: :journeys_session_id

    validates :journey,
      presence: true,
      inclusion: {in: Journeys.all_routing_names}

    def journey_module
      Journeys.for_routing_name(journey)
    end

    def submitted?
      claim.present?
    end
  end
end
