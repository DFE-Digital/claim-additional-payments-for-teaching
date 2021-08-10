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
    return "ineligible" if claim.eligibility.ineligible?
    return "check-your-answers" if claim.submittable?

    # to avoid the #current_slug_index returning 0 when a slug has been deleted in policy::SlugSequence.slugs
    # the next slug needs to be returned. Otherwise the 2nd slug (index 1) will be retuned
    # for 'address'.
    # This happened due to using a link to render the 'address' page from the show action on 'postcode-search'
    return slugs[slugs.index("select-home-address") + 1] if current_slug == "address" && (claim.has_ecp_policy? || claim.policy == MathsAndPhysics)

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
