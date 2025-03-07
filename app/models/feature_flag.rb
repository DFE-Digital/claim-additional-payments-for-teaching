class FeatureFlag < ApplicationRecord
  def self.enabled?(name)
    where(name: name, enabled: true).exists?
  end
end
