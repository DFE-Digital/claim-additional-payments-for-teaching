module EarlyCareerPayments
  # Determines the slugs that make up the claim process for a Early-Career Payments
  # claim. Based on the existing answers on the claim, the sequence of slugs
  # will change. For example, if the claimant has said they are not a supply teacher
  # then they will not answer the two questions that are associated with supply
  # teaching. 'entire-term-contract' and 'employed-directly' will not be part of the sequence.
  #
  # Note that the sequence is recalculated on each call to `slugs` so that it
  # accounts for any changes that may have been made to the claim and always
  # reflects the sequence based on the claim's current state.
  # There are 4 distinct phases of the claimant journey
  class SlugSequence
    include SessionAccessor
    
    ELIGIBILITY_SLUGS = [
      "current-school",
      "nqt-in-academic-year-after-itt",
      "supply-teacher",
      "entire-term-contract",
      "employed-directly",
      "poor-performance",
      "qualification",
      "itt-year",
      "eligible-itt-subject",
      "eligible-degree-subject",
      "teaching-subject-now",
      "check-your-answers-part-one",
      "eligibility-confirmed",
      "eligible-later",
      "future-eligibility"
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
      "doctoral-loan"
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

    # Really this is a combined CurrentClaim
    def initialize(claim)
      @claim = claim
    end

    # Even though we are inside the ECP namespace, this method can modify the
    # slug sequence of both LUP and ECP claims
    def slugs
      overall_eligibility_status = claim.eligibility_status
      lup_claim = claim.for_policy(LevellingUpPremiumPayments)
      ecp_claim = claim.for_policy(EarlyCareerPayments)

      SLUGS.dup.tap do |sequence|
        unless claim.eligibility.employed_as_supply_teacher?
          sequence.delete("entire-term-contract")
          sequence.delete("employed-directly")
        end

        sequence.delete("eligibility-confirmed") unless overall_eligibility_status == :eligible_now
        sequence.delete("eligible-later") unless overall_eligibility_status == :eligible_later

        sequence.delete("personal-bank-account") if claim.bank_or_building_society == "building_society"
        sequence.delete("building-society-account") if claim.bank_or_building_society == "personal_bank_account"

        sequence.delete("teacher-reference-number") if session[:teacher_id]

        if claim.provide_mobile_number == false
          sequence.delete("mobile-number")
          sequence.delete("mobile-verification")
        end

        remove_student_loan_slugs(sequence) if claim.no_student_loan?
        sequence.delete("masters-doctoral-loan") if claim.has_student_loan?
        remove_masters_doctoral_loan_slugs(sequence) if claim.has_masters_doctoral_loan == false
        remove_student_loan_country_slugs(sequence)

        if claim.eligibility.trainee_teacher?
          trainee_teacher_slugs(sequence)
          sequence.delete("eligible-degree-subject") unless lup_claim&.eligibility&.indicated_ineligible_itt_subject?
        else
          sequence.delete("ineligible") unless [:ineligible, :eligible_later].include?(overall_eligibility_status)
          sequence.delete("future-eligibility")
          sequence.delete("eligible-degree-subject") unless ecp_claim&.eligibility&.status == :ineligible && lup_claim&.eligibility&.indicated_ineligible_itt_subject?
        end
      end
    end

    private

    def remove_student_loan_slugs(sequence, slugs = nil)
      slugs ||= %w[
        student-loan-country
        student-loan-how-many-courses
        student-loan-start-date
      ]

      slugs.each { |slug| sequence.delete(slug) }
    end

    def remove_masters_doctoral_loan_slugs(sequence, slugs = nil)
      slugs ||= %w[
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

    # This method swaps out the entire slug sequence and replaces it with this tiny
    # journey.
    def trainee_teacher_slugs(sequence)
      trainee_slugs = %w[
        current-school
        nqt-in-academic-year-after-itt
        eligible-itt-subject
        eligible-degree-subject
        future-eligibility
        ineligible
      ]

      [sequence.dup - trainee_slugs].flatten.each { |slug| sequence.delete(slug) }
    end
  end
end
