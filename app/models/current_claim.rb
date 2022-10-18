# This class is a retrofit to allow a combined journey/flow to cater for more than one type of claim.
#
# Doing so without changing every form in the views and helpers from acting on a single model approach.
#
# All references to `current_claim` used to be on a Claim model, this acts as a wrapper to delegate
# to multiple claims for different policies if a `PolicyConfiguration` specifies multiple policies.
#
# Existing single policy journeys will work as they were (StudentLoans, MathsAndPhysics).
#
# ECP will no longer be a single policy journey. This is being upgraded to handle ECP and LUP in a single journey.
#
# The new ECP & LUP journey will have 2 claims being updated until a claim type is selected and one of these
# claims are submitted, from then on that is the claim to be acted upon after submission.

class CurrentClaim
  attr_reader :claims

  def initialize(claims:)
    @claims = claims
  end

  def for_policy(policy)
    claims.find { |c| c.eligibility_type == "#{policy}::Eligibility" }
  end

  def policies
    claims.collect { |claim| claim.policy }
  end

  # This might need to change default to ECP for now
  def main_claim
    for_policy(EarlyCareerPayments) || claims.first
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

  def submit!(policy)
    policy ||= main_claim.policy

    ActiveRecord::Base.transaction do
      claim = for_policy(policy)
      claim.policy_options_provided = generate_policy_options_provided
      claim.submit!
      destroy_claims_except!(claim)
    end
  end

  def method_missing(method_name, *args, **kwargs, &block)
    if [:attributes=, :save!, :update, :update!, :reset_dependent_answers].include?(method_name)
      claims.each do |c|
        c.send(method_name, *args, **kwargs, &block) unless c == main_claim
      end
    end

    main_claim.send(method_name, *args, **kwargs, &block)
  end

  def save(*args, **kwargs)
    claims.map { |c| c.save(*args, **kwargs) }.all?
  end

  def respond_to_missing?(method_name, *args, **kwargs)
    main_claim.respond_to?(method_name, *args, **kwargs)
  end

  # Always give precedence to returning `:eligible_now` over `:eligible_later`
  # because we only want to use `:eligible_later` if there's nothing eligible
  # now.
  def eligibility_status
    if anything_eligible_now?
      :eligible_now
    elsif anything_eligible_later?
      :eligible_later
    elsif everything_ineligible?
      :ineligible
    else
      :undetermined
    end
  end

  # Non-combined journey code like Student Loans should really
  # be using `eligibility_status` instead of this.
  def ineligible?
    claims.all? { |c| c.eligibility.ineligible? }
  end

  # Non-combined journey code like Student Loans should really
  # be using `eligibility_status` instead of this.
  def eligible_now?
    claims.any? { |c| c.eligibility.eligible_now? }
  end

  # Non-combined journey code like Student Loans should really
  # be using `eligibility_status` instead of this.
  def eligible_later?
    claims.any? { |c| c.eligibility.eligible_later? }
  end

  def editable_attributes
    claims.flat_map { |c| c.eligibility.class::EDITABLE_ATTRIBUTES }.uniq
  end

  def eligible_now
    claims.select { |c| c.eligibility.status == :eligible_now }
  end

  # award_amount highest first, policy name alphabetically if the amount is the same
  def eligible_now_and_sorted
    eligible_now.sort_by { |c| [-c.award_amount.to_i, c.policy.short_name] }
  end

  def set_a_reminder?
    return false unless main_claim

    Reminder.set_a_reminder?(policy_year: policy_year, itt_academic_year: main_claim.eligibility.itt_academic_year)
  end

  # No specific spec for this, but if this is wrong the other specs will show it up
  def policy_year
    raise "nil academic year" if policies.any? { |policy| PolicyConfiguration.for(policy).current_academic_year.nil? }
    raise "none academic year" if policies.any? { |policy| PolicyConfiguration.for(policy).current_academic_year == AcademicYear.new }

    policy_year_values_set = policies.collect { |policy| PolicyConfiguration.for(policy).current_academic_year }.to_set

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

  def anything_eligible_now?
    claims.any? { |claim| claim.eligibility.status == :eligible_now }
  end

  def anything_eligible_later?
    claims.any? { |claim| claim.eligibility.status == :eligible_later }
  end

  def everything_ineligible?
    claims.all? { |claim| claim.eligibility.status == :ineligible }
  end

  def destroy_claims_except!(claim)
    claims.where.not(id: claim.id).destroy_all
    claims.reload
  end

  def generate_policy_options_provided
    return [] unless main_claim.has_ecp_or_lupp_policy?

    eligible_now_and_sorted.map do |c|
      {
        "policy" => c.policy.to_s,
        "award_amount" => BigDecimal(c.award_amount)
      }
    end
  end
end
