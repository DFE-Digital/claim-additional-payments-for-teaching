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
      unsubmitted.where(journeys_sessions: {updated_at: ..purgeable_age})
    end

    scope :expired, -> { where(expired: true) }
    scope :not_expired, -> { where(expired: false) }

    scope :expirable, -> do
      unsubmitted
        .not_expired
        .where(journeys_sessions: {updated_at: ..expirable_age})
    end

    def self.purgeable_age
      24.hours.ago
    end

    def self.expirable_age
      24.hours.ago
    end

    def not_expired?
      !expired?
    end

    def journey_class
      Journeys.for_routing_name(journey)
    end

    def submitted?
      claim.present?
    end
  end
end
