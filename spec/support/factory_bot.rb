RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # This registry ensures the random values selected in factories e.g. using
  # Array#sample are unique, to avoid validation and state errors. Any value
  # used should be removed from the registry.
  #
  # Usage example:
  #
  # code { Thread.current[:factory_registry].find(:local_authority_district_ecp_uplift_codes).shuffle!.pop }
  Thread.current[:factory_registry] = FactoryBot::Registry.new(:uniqueness_guarantor)

  config.before :each do
    Thread.current[:factory_registry].register :local_authority_district_maths_and_physics_eligible_codes, MathsAndPhysics::SchoolEligibility::ELIGIBLE_LOCAL_AUTHORITY_DISTRICT_CODES
    Thread.current[:factory_registry].register :local_authority_district_ecp_uplift_codes, EarlyCareerPayments::SchoolEligibility::UPLIFT_LOCAL_AUTHORITY_DISTRICT_CODES
    Thread.current[:factory_registry].register :local_authority_district_ecp_eligible_codes, EarlyCareerPayments::SchoolEligibility::ELIGIBLE_LOCAL_AUTHORITY_DISTRICT_CODES
  end
end

