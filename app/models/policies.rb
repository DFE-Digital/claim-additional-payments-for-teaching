# Module providing access to all the currently active policies for the service.
module Policies
  POLICIES = [
    StudentLoans,
    MathsAndPhysics,
    EarlyCareerPayments
  ].freeze

  AMENDABLE_ELIGIBILITY_ATTRIBUTES = POLICIES.map { |policy| policy::Eligibility::AMENDABLE_ATTRIBUTES }.flatten.freeze

  def self.all
    POLICIES
  end

  def self.options_for_select
    all.collect { |c| [c.short_name, c.routing_name] }
  end

  # Returns a policy that matches the provided routing name
  # For example:
  #
  #   Policies["student-loans"] #=> StudentLoans
  #
  def self.[](routing_name)
    POLICIES.find { |policy| policy.routing_name == routing_name }
  end
end
