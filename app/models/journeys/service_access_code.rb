module Journeys
  class ServiceAccessCode < ApplicationRecord
    scope :for_journey, ->(journey) { where(journey: journey) }

    scope :used, -> { where(used: true) }
    scope :unused, -> { where(used: false) }

    after_initialize -> { self.code = generate_code if code.blank? }

    normalizes :journey, with: -> { it.to_s }

    validates :code, presence: true, uniqueness: true

    def self.permits_access?(code:, journey:)
      code.present? && for_journey(journey).unused.exists?(code: code)
    end

    def mark_as_used!
      update!(used: true)
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
