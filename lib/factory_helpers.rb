module FactoryHelpers
  extend ActiveSupport::Concern

  def self.create_factory_registry
    Thread.current[:factory_registry] = FactoryBot::Registry.new(:uniqueness_guarantor)
  end
end
