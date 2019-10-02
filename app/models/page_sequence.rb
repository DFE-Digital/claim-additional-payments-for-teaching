# frozen_string_literal: true

# Represents the pages in the claim process.
#
# Depending on the state of `claim`,  the sequence of slugs will change,
# filtering out pages that are not relevant. For example, the sequence for a
# claim that states it is still employed at the same school as the
# `claim_school` will skip the `current-school` page as `current_school` is
# inferred to be the same as `claim_school.
class PageSequence
  CURRENT_SEQUENCE_VERSION = 0

  NON_QUESTION_SLUGS = [
    "check-your-answers",
    "confirmation",
    "ineligible",
  ].freeze

  QUESTION_SLUGS = {
    0 => [
      "qts-year",
      "claim-school",
      "still-teaching",
      "current-school",
      "subjects-taught",
      "leadership-position",
      "mostly-performed-leadership-duties",
      "eligibility-confirmed",
      "information-provided",
      "verified",
      "address",
      "gender",
      "teacher-reference-number",
      "national-insurance-number",
      "student-loan",
      "student-loan-country",
      "student-loan-how-many-courses",
      "student-loan-start-date",
      "student-loan-amount",
      "email-address",
      "bank-details",
    ],
  }.freeze

  attr_reader :claim, :current_slug, :sequence_version

  def self.all_slugs
    [QUESTION_SLUGS.values, NON_QUESTION_SLUGS].flatten.uniq
  end

  def initialize(claim, current_slug, sequence_version:)
    @claim = claim
    @current_slug = current_slug
    @sequence_version = sequence_version
  end

  def slugs
    QUESTION_SLUGS[sequence_version].dup.tap do |sequence|
      sequence.delete("current-school") if claim.eligibility.employed_at_claim_school?
      sequence.delete("mostly-performed-leadership-duties") unless claim.eligibility.had_leadership_position?
      sequence.delete("student-loan-country") if claim.no_student_loan?
      sequence.delete("student-loan-how-many-courses") if claim.no_student_loan? || claim.student_loan_country_with_one_plan?
      sequence.delete("student-loan-start-date") if claim.no_student_loan? || claim.student_loan_country_with_one_plan?
      sequence.delete("address") if claim.address_verified?
      sequence.delete("gender") if claim.payroll_gender_verified?
    end
  end

  def next_slug
    return "ineligible" if claim.eligibility.ineligible?
    return "confirmation" if claim.submitted?
    return "check-your-answers" if claim.submittable?

    slugs.each do |slug|
      break if slug == current_slug

      return slug if claim.invalid?(slug.to_sym)
    end

    next_slug = current_slug_index.nil? ? nil : slugs[current_slug_index + 1]

    if next_slug.nil?
      self.class.all_slugs.detect { |slug| claim.invalid?(slug.to_sym) }
    else
      next_slug
    end
  end

  def in_sequence?(slug)
    slugs.include?(slug) || NON_QUESTION_SLUGS.include?(slug)
  end

  private

  def current_slug_index
    slugs.index(current_slug)
  end
end
