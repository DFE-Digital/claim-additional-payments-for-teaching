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
      "initial-teacher-training-specialised-in-maths-or-physics",
      "has-uk-maths-or-physics-degree",
      "qts-year",
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
      "email-address",
      "bank-details",
      "check-your-answers",
      "ineligible",
    ].freeze

    attr_reader :claim

    def initialize(claim)
      @claim = claim
    end

    def slugs
      SLUGS.dup.tap do |sequence|
        sequence.delete("has-uk-maths-or-physics-degree") if claim.eligibility.initial_teacher_training_specialised_in_maths_or_physics?
        sequence.delete("student-loan-country") if claim.no_student_loan?
        sequence.delete("student-loan-how-many-courses") if claim.no_student_loan? || claim.student_loan_country_with_one_plan?
        sequence.delete("student-loan-start-date") if claim.no_student_loan? || claim.student_loan_country_with_one_plan?
        sequence.delete("address") if claim.address_verified?
        sequence.delete("gender") if claim.payroll_gender_verified?
      end
    end
  end
end
