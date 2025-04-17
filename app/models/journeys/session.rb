module Journeys
  class Session < ApplicationRecord
    self.abstract_class = true

    self.table_name = "journeys_sessions"

    def self.inherited(subclass)
      super

      subclass.attribute :answers, subclass.module_parent::SessionAnswersType.new

      subclass.define_method(:answers) do
        super().tap { it.session = self }
      end
    end

    has_one :claim,
      dependent: :nullify,
      inverse_of: :journey_session,
      foreign_key: :journeys_session_id

    validates :journey,
      presence: true,
      inclusion: {in: Journeys.all_routing_names}

    scope :unsubmitted, -> { where.missing(:claim) }

    scope :submitted, -> { joins(:claim) }

    scope :purgeable, -> do
      unsubmitted.where(journeys_sessions: {updated_at: ..24.hours.ago})
    end

    def journey_class
      Journeys.for_routing_name(journey)
    end

    def submitted?
      claim.present?
    end
  end
end
