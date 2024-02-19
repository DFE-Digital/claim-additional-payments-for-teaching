# frozen_string_literal: true

# Used to model the sequence of pages that make up the claim process.
class PageSequence
  attr_reader :claim, :current_slug, :completed_slugs

  DEAD_END_SLUGS = %w[complete existing-session eligible-later future-eligibility ineligible]
  OPTIONAL_SLUGS = %w[postcode-search no-address-found select-home-address reset-claim]

  def initialize(claim, slug_sequence, completed_slugs, current_slug)
    @claim = claim
    @current_slug = current_slug
    @slug_sequence = slug_sequence
    @completed_slugs = completed_slugs
  end

  def slugs
    @slug_sequence.slugs
  end

  def next_slug
    if lup_policy_and_trainee_teacher_at_lup_school?
      return handle_trainee_teacher
    end

    return "ineligible" if claim.ineligible?

    if claim.submittable?
      return "student-loan-amount" if updating_personal_details? && in_sequence?("student-loan-amount")
      return "check-your-answers"
    end

    return slugs[current_slug_index + 2] if can_skip_next_slug?

    slugs[current_slug_index + 1]
  end

  def previous_slug
    return nil if current_slug_index.zero? || current_slug.in?(DEAD_END_SLUGS)
    slugs[current_slug_index - 1]
  end

  def in_sequence?(slug)
    slugs.include?(slug)
  end

  def has_completed_journey_until?(slug)
    return true if DEAD_END_SLUGS.include?(slug)
    return true if (slug == "address" || claim.postcode.present?) && incomplete_slugs == ["address"]
    return true if claim.policies.include?(MathsAndPhysics) && incomplete_slugs == ["eligibility-confirmed"]
    incomplete_slugs.empty?
  end

  def next_required_slug
    (slugs - completed_slugs - OPTIONAL_SLUGS).first
  end

  private

  def updating_personal_details?
    current_slug == "personal-details"
  end

  def incomplete_slugs
    (slugs.slice(0, current_slug_index) - OPTIONAL_SLUGS - completed_slugs)
  end

  def can_skip_next_slug?
    # This allows 'address' page to be skipped when the postcode is present
    # Occurs when populated from 'postcode-search' and the subsequent 'select-home-address' screens
    true if current_slug == "select-home-address" && claim.postcode.present?
  end

  def lup_policy_and_trainee_teacher_at_lup_school?
    LevellingUpPremiumPayments.in?(claim.policies) && lup_teacher_at_lup_school
  end

  def lup_teacher_at_lup_school
    claim.eligibility.nqt_in_academic_year_after_itt == false && LevellingUpPremiumPayments::SchoolEligibility.new(claim.eligibility.current_school).eligible?
  end

  def handle_trainee_teacher
    case current_slug
    when "nqt-in-academic-year-after-itt"
      if claim.eligibility.nqt_in_academic_year_after_itt?
        "supply-teacher"
      else
        claim.policy_year.in?(EligibilityCheckable::COMBINED_ECP_AND_LUP_POLICY_YEARS_BEFORE_FINAL_YEAR) ? "eligible-itt-subject" : "ineligible"
      end
    when "eligible-itt-subject"
      if claim.eligibility.eligible_itt_subject.to_sym.in? JourneySubjectEligibilityChecker.fixed_lup_subject_symbols
        "future-eligibility"
      else
        "eligible-degree-subject"
      end
    when "eligible-degree-subject"
      lup_claim = claim.for_policy(LevellingUpPremiumPayments)

      if lup_claim.eligibility.eligible_degree_subject?
        "future-eligibility"
      else
        "ineligible"
      end
    end
  end

  def current_slug_index
    slugs.index(current_slug) || 0
  end
end
