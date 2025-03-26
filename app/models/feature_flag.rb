class FeatureFlag < ApplicationRecord
  def self.enabled?(name)
    where(name: name, enabled: true).exists?
  end

  def self.enable!(name)
    find_or_create_by!(name: name).update!(enabled: true)
  end

  def self.disabled?(name)
    !enabled?(name)
  end

  def self.disable!(name)
    find_by(name: name)&.update!(enabled: false)
  end
end
