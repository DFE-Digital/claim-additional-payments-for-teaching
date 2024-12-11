module EligibilityCheckable
  extend ActiveSupport::Concern

  FIRST_COMBINED_ECP_AND_LUP_POLICY_YEAR = AcademicYear.new(2022)
  FINAL_COMBINED_ECP_AND_LUP_POLICY_YEAR = AcademicYear.new(2024)
  COMBINED_ECP_AND_LUP_POLICY_YEARS = FIRST_COMBINED_ECP_AND_LUP_POLICY_YEAR..FINAL_COMBINED_ECP_AND_LUP_POLICY_YEAR
  COMBINED_ECP_AND_LUP_POLICY_YEARS_BEFORE_FINAL_YEAR = FIRST_COMBINED_ECP_AND_LUP_POLICY_YEAR...FINAL_COMBINED_ECP_AND_LUP_POLICY_YEAR

  def status
    if eligible_now?
      :eligible_now
    elsif eligible_later?
      :eligible_later
    elsif ineligible?
      :ineligible
    else
      :undetermined
    end
  end

  def ineligible?
    common_ineligible_attributes? || specific_ineligible_attributes?
  end

  # It's not good to call either `eligible_now?` or `eligible_later?` directly
  # because of the following business rule which is captured in the `status`
  # method above: if a claim is both eligible now and eligible later, it's
  # deemed eligible now. The eligible later option is *only* shown as a consolation
  # prize if there's nothing eligible now.
  #
  # So if a claim is both eligible now and eligible later somebody
  # might check one, find it to be true, and assume the other is false.
  # This is why you see a lot of code checking if something is eligible later
  # but not eligible now and vice versa. Avoid these conundrums by using the
  # `status` method in this class instead which keeps the states mutually exclusive.
  def eligible_now?
    common_eligible_now_attributes? && specific_eligible_now_attributes?
  end

  # Avoid calling this method directly and use the `status` method instead.
  def eligible_later?
    common_eligible_later_attributes? && specific_eligible_later_attributes?
  end

  def trainee_teacher?
    nqt_in_academic_year_after_itt == false
  end

  private

  def common_ineligible_attributes?
    [
      policy_closed?,
      indicated_ineligible_school?,
      supply_teacher_lacking_either_long_contract_or_direct_employment?,
      poor_performance?,
      no_selectable_subjects?,
      ineligible_cohort?,
      insufficient_teaching?
    ].any?
  end

  def policy_closed?
    policy.closed?(claim_year)
  end

  def indicated_ineligible_school?
    current_school.present? && !policy::SchoolEligibility.new(current_school).eligible?
  end

  def supply_teacher_lacking_either_long_contract_or_direct_employment?
    employed_as_supply_teacher? && (has_entire_term_contract == false || employed_directly == false)
  end

  def poor_performance?
    subject_to_formal_performance_action? || subject_to_disciplinary_action?
  end

  def no_selectable_subjects?
    if claim_year.blank? || itt_academic_year.blank?
      false
    else
      policy.current_and_future_subject_symbols(
        claim_year: claim_year,
        itt_year: itt_academic_year
      ).empty?
    end
  end

  def ineligible_cohort?
    return false if itt_academic_year.nil?

    eligible_itt_years = policy.selectable_itt_years_for_claim_year(claim_year)
    !itt_academic_year.in? eligible_itt_years
  end

  def claim_year
    Journeys.for_policy(policy).configuration.current_academic_year
  end

  def insufficient_teaching?
    teaching_subject_now == false
  end

  def common_eligible_now_attributes?
    [indicated_eligible_school?, newly_qualified_teacher?, non_supply_teacher_or_supply_teacher_with_long_contract_and_direct_employment?, good_performance?, eligible_cohort?, sufficient_teaching?].all?
  end

  def newly_qualified_teacher?
    nqt_in_academic_year_after_itt?
  end

  def indicated_eligible_school?
    current_school.present? and policy::SchoolEligibility.new(current_school).eligible?
  end

  def non_supply_teacher_or_supply_teacher_with_long_contract_and_direct_employment?
    (employed_as_supply_teacher == false) || (employed_as_supply_teacher && has_entire_term_contract && employed_directly)
  end

  def good_performance?
    (subject_to_formal_performance_action == false) && (subject_to_disciplinary_action == false)
  end

  def eligible_cohort?
    return false if itt_academic_year.nil?

    eligible_itt_years = policy.selectable_itt_years_for_claim_year(claim_year)
    itt_academic_year.in? eligible_itt_years
  end

  def sufficient_teaching?
    teaching_subject_now?
  end

  def common_eligible_later_attributes?
    any_future_combined_policy_years? && indicated_eligible_school?
  end

  def policy_end_year
    policy::POLICY_END_YEAR
  end

  def any_future_policy_years?
    claim_year < policy_end_year
  end

  def any_future_combined_policy_years?
    claim_year < FINAL_COMBINED_ECP_AND_LUP_POLICY_YEAR
  end
end
