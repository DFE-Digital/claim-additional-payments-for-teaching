class Cache < ApplicationRecord
  def expired?
    return if expires_at.blank?

    Time.zone.now > expires_at
  end
end
