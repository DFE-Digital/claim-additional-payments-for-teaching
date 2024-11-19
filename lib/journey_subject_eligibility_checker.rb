# TODO: Move this into an additional-payments journey specific namespace
#
class JourneySubjectEligibilityChecker
  def initialize(claim_year:, itt_year:)
    raise "Claim year #{claim_year} is after ECP and LUP both ended" if claim_year > EligibilityCheckable::FINAL_COMBINED_ECP_AND_LUP_POLICY_YEAR

    @claim_year = claim_year

    validate_itt_year(itt_year)
    @itt_year = itt_year
  end

  def future_claim_years
    if none_of_the_above_or_blank?(@itt_year)
      []
    else
      ((@claim_year + 1)..EligibilityCheckable::FINAL_COMBINED_ECP_AND_LUP_POLICY_YEAR).to_a
    end
  end

  def self.selectable_subject_symbols(answers)
    if answers.nqt_in_academic_year_after_itt
      new(
        claim_year: answers.policy_year,
        itt_year: answers.itt_academic_year
      ).selectable_subject_symbols(answers)
    elsif answers.policy_year.in?(EligibilityCheckable::COMBINED_ECP_AND_LUP_POLICY_YEARS_BEFORE_FINAL_YEAR)
      # they get the standard, unchanging LUP subject set because they won't have qualified in time for ECP by 2022/2023
      # and they won't have given an ITT year
      fixed_lup_subject_symbols
    else
      []
    end.sort
  end

  # Ideally we wouldn't have this method at all. Unfortunately it was hardcoded like
  # this before we realised trainee teachers weren't as special a case as we
  # thought.
  def self.fixed_lup_subject_symbols
    [:chemistry, :computing, :mathematics, :physics]
  end

  # FIXME RL - should be able to delete all the methods using this
  def current_and_future_subject_symbols(policy)
    (current_subject_symbols(policy) + future_subject_symbols(policy)).uniq
  end

  def current_subject_symbols(policy)
    if none_of_the_above_or_blank?(@itt_year)
      []
    else
      subject_symbols(
        policy: policy,
        claim_year: @claim_year,
        itt_year: @itt_year
      )
    end
  end

  def future_subject_symbols(policy)
    if none_of_the_above_or_blank?(@itt_year)
      []
    else
      future_claim_years.collect { |future_year| subject_symbols(policy: policy, claim_year: future_year, itt_year: @itt_year) }.flatten.uniq
    end
  end

  def selectable_subject_symbols(answers)
    return [] if answers.itt_academic_year.blank?

    potentially_still_eligible_policies(answers).map do |policy|
      current_and_future_subject_symbols(policy)
    end.flatten.uniq
  end

  private

  # Move this
  def potentially_still_eligible_policies(answers)
    Journeys::AdditionalPaymentsForTeaching::POLICIES.select do |policy|
      policy::PolicyEligibilityChecker.new(answers: answers).status != :ineligible
    end
  end

  def validate_itt_year(itt_year)
    unless none_of_the_above_or_blank?(itt_year)
      raise "ITT year #{itt_year} is outside the window for claim year #{@claim_year}" unless itt_year.in?(Journeys::AdditionalPaymentsForTeaching.selectable_itt_years_for_claim_year(@claim_year))
    end
  end

  def none_of_the_above_or_blank?(itt_year)
    itt_year.blank? || none_of_the_above?(itt_year)
  end

  def none_of_the_above?(itt_year)
    itt_year.in? [AcademicYear.new, "None"]
  end

  def subject_symbols(policy:, claim_year:, itt_year:)
    raise "Unsupported policy: #{policy}" unless policy.in?(Journeys::AdditionalPaymentsForTeaching::POLICIES)

    policy.subject_symbols(claim_year: claim_year, itt_year: itt_year)
  end
end
