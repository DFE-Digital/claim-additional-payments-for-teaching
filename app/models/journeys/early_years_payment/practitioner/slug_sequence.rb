module Journeys
  module EarlyYearsPayment
    module Practitioner
      class SlugSequence
        SLUGS = %w[
          find-reference
          how-we-use-your-information
          sign-in
          full-name
          date-of-birth
          national-insurance-number
          postcode-search
          select-home-address
          address
          email-address
          email-verification
          provide-mobile-number
          mobile-number
          mobile-verification
          personal-bank-account
          gender
          check-your-answers
          confirmation
          ineligible
        ].freeze

        RESTRICTED_SLUGS = [].freeze

        DEAD_END_SLUGS = %w[
          confirmation
          ineligible
        ]

        def self.start_page_url
          Rails
            .application.routes
            .url_helpers
            .landing_page_path("early-years-payment-practitioner")
        end

        def self.signed_out_path
          Rails
            .application
            .routes
            .url_helpers
            .claim_path("early-years-payment-practitioner", "signed-out")
        end

        attr_reader :journey_session

        delegate :answers, to: :journey_session

        def initialize(journey_session)
          @journey_session = journey_session
        end

        def slugs
          [].tap do |sequence|
            sequence << "find-reference"
            sequence << "sign-in"
            sequence << "how-we-use-your-information"
            sequence << "full-name" if show_full_name?
            sequence << "date-of-birth" if show_date_of_birth?
            sequence << "national-insurance-number"
            sequence << "postcode-search" unless answers.ordnance_survey_error?
            sequence << "select-home-address" if answers.postcode_searched?
            sequence << "address" unless answers.postcode_searched?
            sequence << "email-address"
            sequence << "email-verification" unless answers.email_verified?
            sequence << "provide-mobile-number"
            sequence << "mobile-number" unless answers.provide_mobile_number == false
            sequence << "mobile-verification" unless answers.provide_mobile_number == false
            sequence << "personal-bank-account"
            sequence << "gender"
            sequence << "check-your-answers"
            sequence << "confirmation"
          end
        end

        def journey
          Journeys::EarlyYearsPayment::Practitioner
        end

        private

        def show_full_name?
          !answers.identity_confirmed_with_onelogin?
        end

        def show_date_of_birth?
          !answers.identity_confirmed_with_onelogin?
        end
      end
    end
  end
end
