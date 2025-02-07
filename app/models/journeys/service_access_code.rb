module Journeys
  class ServiceAccessCode < ApplicationRecord
    scope :for_journey, ->(journey) { where(journey: journey) }

    scope :used, -> do
      joins(
        <<~SQL
          JOIN journeys_sessions
          ON journeys_service_access_codes.code = journeys_sessions.answers ->> 'service_access_code'
        SQL
      ).merge(Journeys::Session.submitted)
    end

    scope :unused, -> { where.not(id: used) }

    after_initialize -> { self.code = generate_code if code.blank? }

    normalizes :journey, with: -> { it.to_s }

    validates :code, presence: true, uniqueness: true

    def self.permits_access?(code:, journey:)
      code.present? && for_journey(journey).unused.exists?(code: code)
    end

    private

    def generate_code
      loop {
        code = Reference.new.to_s
        break code unless self.class.exists?(code: code)
      }
    end
  end
end
