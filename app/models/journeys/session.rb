module Journeys
  class Session < ApplicationRecord
    self.abstract_class = true

    has_one :claim,
      dependent: :nullify,
      inverse_of: :journeys_session,
      foreign_key: :journeys_session_id

    validates :journey,
      presence: true,
      inclusion: {in: Journeys.all_routing_names}

    def submitted?
      claim.present?
    end
  end
end
