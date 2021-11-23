module MathsAndPhysics
  # Determines the slugs that make up the claim process for a Maths & Physics
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
      "teaching-maths-or-physics",
      "current-school",
      "initial-teacher-training-subject",
      "initial-teacher-training-subject-specialism",
      "has-uk-maths-or-physics-degree",
      "qts-year",
      "supply-teacher",
      "entire-term-contract",
      "employed-directly",
      "disciplinary-action",
      "formal-performance-action",
      "eligibility-confirmed",
      "information-provided",
      "personal-details",
      "postcode-search",
      "no-address-found",
      "select-home-address",
      "address",
      "gender",
      "teacher-reference-number",
      "student-loan",
      "student-loan-country",
      "student-loan-how-many-courses",
      "student-loan-start-date",
      "masters-doctoral-loan",
      "masters-loan",
      "doctoral-loan",
      "email-address",
      "email-verification",
      "provide-mobile-number",
      "mobile-number",
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
        sequence.delete("initial-teacher-training-subject-specialism") unless claim.eligibility.itt_subject_science?
        sequence.delete("has-uk-maths-or-physics-degree") if claim.eligibility.initial_teacher_training_specialised_in_maths_or_physics?
        sequence.delete("entire-term-contract") unless claim.eligibility.employed_as_supply_teacher?
        sequence.delete("employed-directly") unless claim.eligibility.employed_as_supply_teacher?
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
        sequence.delete("ineligible") unless claim.eligibility.ineligible?
      end
    end
  end
end
