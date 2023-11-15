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
    ELIGIBILITY_SLUGS = [
      "sign-in-or-continue",
      "teacher-detail",
      "reset-claim",
      "qts-year",
      "claim-school",
      "subjects-taught",
      "still-teaching",
      "current-school",
      "leadership-position",
      "mostly-performed-leadership-duties",
      "eligibility-confirmed"
    ].freeze

    PERSONAL_DETAILS_SLUGS = [
      "information-provided",
      "personal-details",
      "postcode-search",
      "no-address-found",
      "select-home-address",
      "address",
      "email-address",
      "email-verification",
      "provide-mobile-number",
      "mobile-number",
      "mobile-verification"
    ].freeze

    PAYMENT_DETAILS_SLUGS = [
      "bank-or-building-society",
      "personal-bank-account",
      "building-society-account",
      "gender",
      "teacher-reference-number"
    ].freeze

    STUDENT_LOANS_SLUGS = [
      "student-loan",
      "student-loan-country",
      "student-loan-how-many-courses",
      "student-loan-start-date",
      "masters-doctoral-loan",
      "masters-loan",
      "doctoral-loan",
      "student-loan-amount"
    ].freeze

    RESULTS_SLUGS = [
      "check-your-answers",
      "ineligible"
    ].freeze

    SLUGS = (
      ELIGIBILITY_SLUGS +
      PERSONAL_DETAILS_SLUGS +
      PAYMENT_DETAILS_SLUGS +
      STUDENT_LOANS_SLUGS +
      RESULTS_SLUGS
    ).freeze

    attr_reader :claim

    def initialize(claim)
      @claim = claim
    end

    def slugs
      SLUGS.dup.tap do |sequence|
        sequence.delete("teacher-detail") if claim.logged_in_with_tid.nil?
        sequence.delete("reset-claim") if [nil, true].include?(claim.logged_in_with_tid)
        sequence.delete("current-school") if claim.eligibility.employed_at_claim_school?
        sequence.delete("mostly-performed-leadership-duties") unless claim.eligibility.had_leadership_position?
        sequence.delete("student-loan-country") if claim.no_student_loan?
        sequence.delete("student-loan-how-many-courses") if claim.no_student_loan? || claim.student_loan_country_with_one_plan?
        sequence.delete("student-loan-start-date") if claim.no_student_loan? || claim.student_loan_country_with_one_plan?
        sequence.delete("masters-doctoral-loan") if claim.has_student_loan?
        sequence.delete("masters-loan") if claim.has_masters_doctoral_loan == false
        sequence.delete("doctoral-loan") if claim.has_masters_doctoral_loan == false
        sequence.delete("personal-bank-account") if claim.bank_or_building_society == "building_society"
        sequence.delete("building-society-account") if claim.bank_or_building_society == "personal_bank_account"
        sequence.delete("mobile-number") if claim.provide_mobile_number == false
        sequence.delete("mobile-verification") if claim.provide_mobile_number == false
        sequence.delete("ineligible") unless claim.eligibility&.ineligible?
        sequence.delete("personal-details") if claim.logged_in_with_tid? && claim.has_all_valid_personal_details?
      end
    end
  end
end
