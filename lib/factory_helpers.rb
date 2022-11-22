module FactoryHelpers
  extend ActiveSupport::Concern

  def self.create_factory_registry
    Thread.current[:factory_registry] = FactoryBot::Registry.new(:uniqueness_guarantor)
  end

  def self.reset_factory_registry
    Thread.current[:factory_registry].register :local_authority_district_maths_and_physics_eligible_codes, MathsAndPhysics::SchoolEligibility::ELIGIBLE_LOCAL_AUTHORITY_DISTRICT_CODES
    Thread.current[:factory_registry].register :local_authority_district_ecp_uplift_codes, EarlyCareerPayments::SchoolEligibility::UPLIFT_LOCAL_AUTHORITY_DISTRICT_CODES
    Thread.current[:factory_registry].register :local_authority_district_ecp_eligible_codes, EarlyCareerPayments::SchoolEligibility::ELIGIBLE_LOCAL_AUTHORITY_DISTRICT_CODES
  end
end
