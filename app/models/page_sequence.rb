# frozen_string_literal: true

# Used to model the sequence of pages that make up the claim process.
class PageSequence
  attr_reader :claim, :current_slug

  def initialize(claim, slug_sequence, current_slug)
    @claim = claim
    @current_slug = current_slug
    @slug_sequence = slug_sequence
  end

  def slugs
    @slug_sequence.slugs
  end

  def next_slug
    if lup_policy_and_trainee_teacher_at_lup_school?
      return handle_trainee_teacher
    end

    return "ineligible" if claim.ineligible?
    return "check-your-answers" if claim.submittable?

    # This allows 'address' page to be skipped when the postcode is present
    # Occurs when populated from 'postcode-search' and the subsequent 'select-home-address' screens
    return slugs[slugs.index("select-home-address") + 2] if current_slug == "select-home-address" && claim.postcode.present?

    slugs[current_slug_index + 1]
  end

  def previous_slug
    slug_index = current_slug_index
    dead_end_slugs = %w[complete existing-session eligible-now eligible-later ineligible]

    return nil if slug_index.zero? || current_slug.in?(dead_end_slugs)
    slugs[slug_index - 1]
  end

  def in_sequence?(slug)
    slugs.include?(slug)
  end

  private

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
