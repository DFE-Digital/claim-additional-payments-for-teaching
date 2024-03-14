module Policies
  POLICIES = [
    StudentLoans,
    EarlyCareerPayments,
    LevellingUpPremiumPayments,
    Irp
  ].freeze

  AMENDABLE_ELIGIBILITY_ATTRIBUTES = POLICIES.map do |policy|
    policy::Eligibility::AMENDABLE_ATTRIBUTES
  end.flatten.freeze

  def self.all
    POLICIES
  end

  def self.options_for_select
    all.collect { |c| [c.short_name, c.policy_type] }
  end

  # Returns a policy that matches the provided policy_type
  #
  # For example:
  #
  #   Policies["student-loans"] #=> StudentLoans
  #
  # Use StudentLoans#policy_type to get "student-loans"
  #
  def self.[](policy_type)
    POLICIES.find { |policy| policy.policy_type == policy_type }
  end

  # Map PolicyConfiguration.policy_types and Claim.policy_options_provided to the Policies namespace
  #
  def self.constantize(policy)
    if %w[EarlyCareerPayments].include?(policy)
      "Policies::#{policy}"
    else
      policy
    end.constantize
  end
end
