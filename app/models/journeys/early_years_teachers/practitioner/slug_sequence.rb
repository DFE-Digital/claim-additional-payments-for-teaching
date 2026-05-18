module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class SlugSequence
        SLUGS = %w[
          sign-in
          one-login-callback-success
          eligibility-confirmed
          payment-not-accepted
          payment-options
          how-we-use-your-information
          postcode-search
          select-home-address
          address
          personal-bank-account
          gender
          check-your-answers
          confirmation
        ].freeze

        RESTRICTED_SLUGS = %w[].freeze

        DEAD_END_SLUGS = %w[
          payment-not-accepted
          confirmation
        ].freeze

        def initialize(journey_session)
          @journey_session = journey_session
        end

        def slugs
          array = []

          array << "sign-in"
          array << "one-login-callback-success"

          array << "eligibility-confirmed"

          if answers.accept_payment == false
            array << "payment-not-accepted"
            return array
          end

          array << "payment-options"

          array << "how-we-use-your-information"

          array << "postcode-search"
          array << "select-home-address" unless answers.skip_postcode_search? || answers.ordnance_survey_error?
          array << "address" if answers.skip_postcode_search? || answers.ordnance_survey_error?

          array << "personal-bank-account"
          array << "gender"

          array << "check-your-answers"

          array << "confirmation"

          array
        end

        private

        delegate :answers, to: :@journey_session
      end
    end
  end
end
