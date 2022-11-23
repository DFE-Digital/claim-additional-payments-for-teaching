module Deletable
  extend ActiveSupport::Concern

  included do
    def self.not_deleted
      where(deleted_at: nil)
    end
  end

  def deleted?
    deleted_at.present?
  end

  def mark_as_deleted!
    return if deleted?

    update!(deleted_at: Time.zone.now)
  end
end
