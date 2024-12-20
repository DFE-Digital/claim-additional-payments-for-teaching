module Policies
  POLICIES = [
    StudentLoans,
    EarlyCareerPayments,
    LevellingUpPremiumPayments,
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

  # Claimants can't claim for these policy combinations in the same academic
  # year
  INVALID_POLICY_COMBINATIONS = [
    [EarlyCareerPayments, EarlyYearsPayments],
    [EarlyCareerPayments, FurtherEducationPayments],
    [EarlyCareerPayments, LevellingUpPremiumPayments],
    [EarlyYearsPayments, FurtherEducationPayments],
    [EarlyYearsPayments, LevellingUpPremiumPayments],
    [FurtherEducationPayments, LevellingUpPremiumPayments],
    [FurtherEducationPayments, StudentLoans],
    [FurtherEducationPayments, InternationalRelocationPayments]
  ]

  def self.prohibited_policy_combination?(policies)
    policies.combination(2).any? do |policy1, policy2|
      INVALID_POLICY_COMBINATIONS.include?([policy1, policy2].sort_by(&:to_s))
    end
  end
end
