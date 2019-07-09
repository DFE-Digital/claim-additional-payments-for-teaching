# frozen_string_literal: true

# Represents the pages in the claim process.
#
# Depending on the state of `claim`,  the sequence of slugs will change,
# filtering out pages that are not relevant. For example, the sequence for a
# claim that states it is still employed at the same school as the
# `claim_school` will skip the `current-school` page as `current_school` is
# inferred to be the same as `claim_school.
class PageSequence
  SLUGS = [
    "qts-year",
    "claim-school",
    "still-teaching",
    "current-school",
    "subjects-taught",
    "mostly-teaching-eligible-subjects",
    "eligibility-confirmed",
    "full-name",
    "address",
    "date-of-birth",
    "teacher-reference-number",
    "national-insurance-number",
    "student-loan-amount",
    "email-address",
    "bank-details",
    "check-your-answers",
    "confirmation",
    "ineligible",
  ].freeze

  attr_reader :claim, :current_slug

  def initialize(claim, current_slug)
    @claim = claim
    @current_slug = current_slug
  end

  def slugs
    SLUGS.dup.tap do |sequence|
      sequence.delete("current-school") if claim.employed_at_claim_school?
    end
  end

  def next_slug
    return "ineligible" if claim.ineligible?

    slugs[current_slug_index + 1]
  end

  private

  def current_slug_index
    slugs.index(current_slug)
  end
end
