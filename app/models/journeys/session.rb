module Journeys
  class Session < ApplicationRecord
    validates :journey,
      presence: true,
      inclusion: {in: Journeys.all_routing_names}
  end
end
