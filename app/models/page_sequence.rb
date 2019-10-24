# frozen_string_literal: true

# Represents the pages in the claim process.
#
# Depending on the state of `claim`,  the sequence of slugs will change,
# filtering out pages that are not relevant. For example, the sequence for a
# claim that states it is still employed at the same school as the
# `claim_school` will skip the `current-school` page as `current_school` is
# inferred to be the same as `claim_school.
class PageSequence
  attr_reader :claim, :current_slug

  def initialize(claim, current_slug)
    @claim = claim
    @current_slug = current_slug
  end

  def slugs
    StudentLoans::SlugSequence.new(claim).slugs
  end

  def next_slug
    return "ineligible" if claim.eligibility.ineligible?
    return "check-your-answers" if claim.submittable?

    slugs[current_slug_index + 1]
  end

  def in_sequence?(slug)
    slugs.include?(slug)
  end

  private

  def current_slug_index
    slugs.index(current_slug) || 0
  end
end
