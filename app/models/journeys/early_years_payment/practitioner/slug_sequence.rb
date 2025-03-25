module Journeys
  module EarlyYearsPayment
    module Practitioner
      class SlugSequence
        CLAIM_SLUGS = %w[
          find-reference
          how-we-use-your-information
          sign-in
          personal-details
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
        ].freeze

        RESULTS_SLUGS = %w[
          check-your-answers
          ineligible
        ].freeze

        SLUGS = (CLAIM_SLUGS + RESULTS_SLUGS).freeze

        def self.start_page_url
          Rails.application.routes.url_helpers.claim_path("early-years-payment-practitioner", "find-reference", skip_landing_page: true)
        end

        attr_reader :journey_session

        delegate :answers, to: :journey_session

        def initialize(journey_session)
          @journey_session = journey_session
        end

        def slugs
          SLUGS.dup.tap do |sequence|
            if answers.provide_mobile_number == false
              sequence.delete("mobile-number")
              sequence.delete("mobile-verification")
            end
          end
        end
      end
    end
  end
end
