# Module providing access to all the currently active policies for the service.
module Policies
  POLICIES = [
    StudentLoans,
    MathsAndPhysics,
  ].freeze

  def self.all
    POLICIES
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
