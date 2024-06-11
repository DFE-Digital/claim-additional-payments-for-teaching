# This class is a retrofit to allow a combined journey/flow to cater for more than one type of claim.
#
# Doing so without changing every form in the views and helpers from acting on a single model approach.
#
# All references to `current_claim` used to be on a Claim model, this acts as a wrapper to delegate
# to multiple claims for different policies if a `Journeys::Configuration` specifies multiple policies.
#
# Existing single policy journeys will work as they were.
#
# ECP will no longer be a single policy journey. This is being upgraded to handle ECP and LUP in a single journey.
#
# The new ECP & LUP journey will have 2 claims being updated until a claim type is selected and one of these
# claims are submitted, from then on that is the claim to be acted upon after submission.

class CurrentClaim
  UnselectablePolicyError = Class.new(StandardError)

  attr_reader :claims, :selected_policy

  def initialize(claims:, selected_policy: nil)
    @claims = claims
    @selected_policy = selected_policy
  end

  def for_policy(policy)
    claims.find do |c|
      c.eligibility_type == Policies.constantize(policy)::Eligibility.to_s
    end
  end

  def policies
    claims.collect { |claim| claim.policy }
  end

  # The "main" claim should to be selected carefully for combined journeys.
  # In the post-eligibility (or claim) phase, validations are run against it
  # to make sure the correct slug sequence is enforced, so it's important to
  # forward to the correct (selected) claim, especially when validations differ.
  def main_claim
    for_policy(main_policy)
  end

  # method_missing does not catch this
  def to_param
    main_claim.to_param
  end

  def claim_ids
    claims.map(&:id)
  end

  def reset_eligibility_dependent_answers(reset_attrs = [])
    claims.each do |c|
      c.eligibility.reset_dependent_answers(reset_attrs)
    end
  end

  def method_missing(method_name, ...)
    if [:attributes=, :save!, :update, :update!, :reset_dependent_answers, :update_attribute, :assign_attributes].include?(method_name)
      claims.each do |c|
        c.send(method_name, ...) unless c == main_claim
      end
    end

    main_claim.send(method_name, ...)
  end

  def save(*, **)
    claims.map { |c| c.save(*, **) }.all?
  end

  def respond_to_missing?(method_name, *, **)
    main_claim.respond_to?(method_name, *, **)
  end

  # Persistence should to be checked for all claims in non-combined journeys.
  def persisted?
    claims.all? { |c| c.persisted? }
  end

  def set_a_reminder?
    return false unless main_claim

    Reminder.set_a_reminder?(policy_year: policy_year, itt_academic_year: main_claim.eligibility.itt_academic_year)
  end

  # No specific spec for this, but if this is wrong the other specs will show it up
  def policy_year
    raise "nil academic year" if policies.any? { |policy| Journeys.for_policy(policy).configuration.current_academic_year.nil? }
    raise "none academic year" if policies.any? { |policy| Journeys.for_policy(policy).configuration.current_academic_year == AcademicYear.new }

    policy_year_values_set = policies.collect { |policy| Journeys.for_policy(policy).configuration.current_academic_year }.to_set

    if policy_year_values_set.one?
      policy_year_values_set.first
    elsif policy_year_values_set.many?
      raise "Have more than one policy year in the same journey"
    else
      raise "Have no policy year for the journey"
    end
  end

  def eligible_eligibility
    claims.sort_by(&:eligibility_type).each do |claim|
      return claim.eligibility unless claim.eligibility.ineligible?
    end

    main_claim.eligibility
  end

  private

  def single_claim?
    claims.one?
  end

  def ecp_or_lupp_claims?
    claims.any? { |c| c.has_ecp_or_lupp_policy? }
  end

  # The "main" policy should always be:
  # - The one and only one available for non-combined journeys
  # - The one from the claim type selected at the end of combined eligibility journeys
  # - ECP for ECP/LUP until one is selected at the end of the eligibility journey
  # It should raise otherwise; this may need to be updated for future combined journeys.
  def main_policy
    return claims.first.policy if single_claim?
    return selected_policy if selected_policy.present?
    return Policies::EarlyCareerPayments if ecp_or_lupp_claims?

    raise UnselectablePolicyError
  end
end
