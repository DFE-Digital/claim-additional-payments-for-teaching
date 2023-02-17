# frozen_string_literal: true

module SimplePolicyPayments
  # Determines the slugs that make up the claim process for a Policy
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
      # email address
      'email-address',
      'email-verification',

      # names, DoB, NINo
      'personal-details',

      # school is required
      'current_school',

      # TRN for Qualifications, Pension and Workforce searches
      'teacher-reference-number',
      # should do DQT search here

      # personal address
      'postcode-search',
      'no-address-found',
      'select-home-address',
      'address',

      # payment details phase
      'bank-or-building-society',
      'personal-bank-account',
      'building-society-account',
      # should do bank checks here

      'gender', # HMRC payroll requirement ??

      # loans checks
      'student-loan',
      'student-loan-country',
      'student-loan-how-many-courses',
      'student-loan-start-date',
      'masters-doctoral-loan',
      'masters-loan',
      'doctoral-loan',

      # mobile number - optional
      'provide-mobile-number',
      'mobile-number',
      'mobile-verification',

      'check-your-answers',
      'ineligible'
    ].freeze

    attr_reader :claim

    def initialize(claim)
      @claim = claim
    end

    def slugs
      SLUGS.dup.tap do |sequence|
        sequence.delete('personal-bank-account') if claim.bank_or_building_society == 'building_society'
        sequence.delete('building-society-account') if claim.bank_or_building_society == 'personal_bank_account'

        sequence.delete('mobile-number') if claim.provide_mobile_number == false
        sequence.delete('mobile-verification') if claim.provide_mobile_number == false

        sequence.delete('student-loan-country') if claim.no_student_loan?
        sequence.delete('student-loan-how-many-courses') if claim.no_student_loan?
        sequence.delete('student-loan-start-date') if claim.no_student_loan?

        sequence.delete('masters-doctoral-loan') if claim.has_student_loan?

        sequence.delete('masters-loan') if claim.has_masters_doctoral_loan == false
        sequence.delete('doctoral-loan') if claim.has_masters_doctoral_loan == false

        sequence.delete('ineligible') unless claim.ineligible?
      end
    end
  end
end