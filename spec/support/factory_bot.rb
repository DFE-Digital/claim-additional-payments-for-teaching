require "./lib/factory_helpers"

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # This registry ensures the random values selected in factories e.g. using
  # Array#sample are unique, to avoid validation and state errors. Any value
  # used should be removed from the registry.
  #
  # Usage example:
  #
  # code { Thread.current[:factory_registry].find(:local_authority_district_ecp_uplift_codes).shuffle!.pop }
  FactoryHelpers.create_factory_registry

  config.before :each do
    FactoryHelpers.reset_factory_registry
  end
end
