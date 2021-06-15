module EarlyCareerPayments
  # Determines the slugs that make up the claim process for a Early-Career Payments
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
      "current-school",
      "supply-teacher",
      "entire-term-contract",
      "employed-directly",
      "formal-performance-action",
      "disciplinary-action",
      "postgraduate-itt-or-undergraduate-itt-course",
      "eligible-itt-subject",
      "teaching-subject-now",
      "itt-year",
      "check-your-answers-part-one",
      "eligibility-confirmed",
      # eligible later phase of claim journey
      # personal details phase of claim journey
      "how-we-will-use-information-provided",
      "personal-details",
      "address",
      "email-address",
      "email-verification",
      "bank-details",
      "gender",
      "teacher-reference-number",
      # student loans phase of claim journey
      "student-loan",
      "student-loan-country",
      "student-loan-how-many-courses",
      "student-loan-start-date",
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
        sequence.delete("eligibility-confirmed") unless claim.eligibility.eligible?
        sequence.delete("ineligible") unless claim.eligibility.ineligible?
        remove_student_loan_slugs(sequence) if claim.has_student_loan == false
        remove_student_loan_country_slugs(sequence)
      end
    end

    private

    def remove_student_loan_slugs(sequence, slugs = nil)
      slugs ||= %w[
        student-loan-country
        student-loan-how-many-courses
        student-loan-start-date
        masters-loan
        doctoral-loan
      ]

      slugs.each { |slug| sequence.delete(slug) }
    end

    def remove_student_loan_country_slugs(sequence)
      slugs = %w[
        student-loan-how-many-courses
        student-loan-start-date
      ]

      if [
        StudentLoan::NORTHERN_IRELAND,
        StudentLoan::SCOTLAND
      ].include?(claim.student_loan_country)
        remove_student_loan_slugs(sequence, slugs)
      end
    end
  end
end
