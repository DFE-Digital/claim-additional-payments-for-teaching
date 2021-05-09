module EarlyCareerPayments
  # Determines the slugs that make up the claim process for a Early Career Payments
  # claim. Based on the existing answers on the claim, the sequence of slugs
  # will change. For example, if the claimant has said they are
  # FIXME change when exclusions are known
  # will not be part of the sequence.
  #
  # Note that the sequence is recalculated on each call to `slugs` so that it
  # accounts for any changes that may have been made to the claim and always
  # reflects the sequence based on the claim's current state.
  # There are 4 distinct phases of the claimant journey
  class SlugSequence
    SLUGS = [
      # eligibility phase of claim journey
      "nqt-in-academic-year-after-itt",
      "supply-teacher",
      "entire-term-contract",
      "employed-directly",
      "formal-performance-action",
      "disciplinary-action",
      "postgraduate-itt-or-undergraduate-itt-course",
      "eligible-itt-subject",
      "teaching-subject-now",
      "itt_year",
      "check-your-answers-part-one",
      # eligible later phase of claim journey
      # personal details phase of claim journey
      "how_we_will_use_information_provided",
      "personal-details",
      "address",
      "email-address",
      "bank-details",
      "gender",
      "teacher-reference-number",
      # student loans phase of claim journey
      "student-loan",
      "masters-loan",
      "doctoral-loan",
      "check-your-answers",
      "ineligible"
    ].freeze

    attr_reader :claim

    def initialize(claim)
      @claim = claim
    end

    def slugs
      SLUGS.dup.tap do |sequence|
        sequence.delete("entire-term-contract") unless claim.eligibility.employed_as_supply_teacher?
        sequence.delete("employed-directly") unless claim.eligibility.employed_as_supply_teacher?
        sequence.delete("ineligible") unless claim.eligibility.ineligible?
      end
    end
  end
end
