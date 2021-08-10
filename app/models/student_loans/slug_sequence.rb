module StudentLoans
  # Determines the slugs that make up the claim process for a Student Loans
  # claim. Based on the existing answers on the claim, the sequence of slugs
  # will change. For example, if the claimant has said they are not paying off a
  # student loan, the questions to determine their loan plan will not be part of
  # the sequence.
  #
  # Note that the sequence is recalculated on each call to `slugs` so that it
  # accounts for any changes that may have been made to the claim and always
  # reflects the sequence based on the claim's current state.
  class SlugSequence
    SLUGS = [
      "qts-year",
      "claim-school",
      "subjects-taught",
      "still-teaching",
      "current-school",
      "leadership-position",
      "mostly-performed-leadership-duties",
      "eligibility-confirmed",
      "information-provided",
      "name",
      "postcode-search",
      "select-home-address",
      "address",
      "date-of-birth",
      "gender",
      "teacher-reference-number",
      "national-insurance-number",
      "student-loan",
      "student-loan-country",
      "student-loan-how-many-courses",
      "student-loan-start-date",
      "student-loan-amount",
      "masters-loan",
      "doctoral-loan",
      "email-address",
      "email-verification",
      "provide-mobile-number",
      "mobile-number",
      "mobile-verification",
      "bank-or-building-society",
      "personal-bank-account",
      "building-society-account",
      "check-your-answers",
      "ineligible"
    ].freeze

    attr_reader :claim

    def initialize(claim)
      @claim = claim
    end

    def slugs
      SLUGS.dup.tap do |sequence|
        sequence.delete("current-school") if claim.eligibility.employed_at_claim_school?
        sequence.delete("mostly-performed-leadership-duties") unless claim.eligibility.had_leadership_position?
        sequence.delete("student-loan-country") if claim.no_student_loan?
        sequence.delete("student-loan-how-many-courses") if claim.no_student_loan? || claim.student_loan_country_with_one_plan?
        sequence.delete("student-loan-start-date") if claim.no_student_loan? || claim.student_loan_country_with_one_plan?
        sequence.delete("masters-loan") if claim.no_student_loan?
        sequence.delete("doctoral-loan") if claim.no_student_loan?
        sequence.delete("personal-bank-account") if claim.bank_or_building_society == "building_society"
        sequence.delete("building-society-account") if claim.bank_or_building_society == "personal_bank_account"
        sequence.delete("mobile-number") if claim.provide_mobile_number == false
        sequence.delete("mobile-verification") if claim.provide_mobile_number == false
        sequence.delete("address") unless claim.address.blank?
        sequence.delete("ineligible") unless claim.eligibility.ineligible?
      end
    end
  end
end
