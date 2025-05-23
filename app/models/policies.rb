module Policies
  POLICIES = [
    StudentLoans,
    EarlyCareerPayments,
    TargetedRetentionIncentivePayments,
    InternationalRelocationPayments,
    FurtherEducationPayments,
    EarlyYearsPayments
  ].freeze

  AMENDABLE_ELIGIBILITY_ATTRIBUTES = POLICIES.map do |policy|
    policy::Eligibility::AMENDABLE_ATTRIBUTES
  end.flatten.uniq.freeze

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
  #   Policies["student-loans"] #=> Policies::StudentLoans
  #
  # Use StudentLoans#policy_type to get "student-loans"
  #
  def self.[](policy_type)
    POLICIES.find { |policy| policy.policy_type == policy_type }
  end

  # Map Claim.policy_options_provided to the Policies namespace
  #
  def self.constantize(policy)
    "Policies::#{policy}".constantize
  end

  def self.with_attribute(attr)
    POLICIES.select { |policy| policy::Eligibility.has_attribute?(attr) }
  end

  def self.from_policy_string(string)
    Policies.all.find { |p| p.name == string }
  end
end
