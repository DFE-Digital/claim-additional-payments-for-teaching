class FeatureFlag < ApplicationRecord
  def self.enabled?(name)
    where(name: name, enabled: true).exists?
  end

  def self.disabled?(name)
    !enabled?(name)
  end
end
