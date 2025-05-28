module Journeys
  module GetATeacherRelocationPayment
    class SlugSequence
      ELIGIBILITY_SLUGS = [
        "application-route",
        "state-funded-secondary-school",
        "current-school",
        "headteacher-details",
        "contract-details",
        "start-date",
        "subject",
        "changed-workplace-or-new-contract",
        "visa",
        "entry-date",
        "check-your-answers-part-one"
      ]

      PERSONAL_DETAILS_SLUGS = [
        "nationality",
        "passport-number",
        "personal-details",
        "postcode-search",
        "select-home-address",
        "address",
        "email-address",
        "email-verification",
        "provide-mobile-number",
        "mobile-number",
        "mobile-verification"
      ]

      PAYMENT_DETAILS_SLUGS = [
        "personal-bank-account",
        "gender"
      ].freeze

      RESULTS_SLUGS = [
        "check-your-answers",
        "ineligible"
      ].freeze

      DEAD_END_SLUGS = [
        "ineligible"
      ]

      SLUGS = (
        ELIGIBILITY_SLUGS +
        PERSONAL_DETAILS_SLUGS +
        PAYMENT_DETAILS_SLUGS +
        RESULTS_SLUGS
      ).freeze

      RESTRICTED_SLUGS = [].freeze

      def self.start_page_url
        if Rails.env.production?
          "https://www.gov.uk/government/publications/international-relocation-payments/international-relocation-payments"
        else
          Rails.application.routes.url_helpers.landing_page_path("get-a-teacher-relocation-payment")
        end
      end

      attr_reader :journey_session

      delegate :answers, to: :journey_session

      def initialize(journey_session)
        @journey_session = journey_session
      end

      def slugs
        SLUGS.dup.tap do |sequence|
          if answers.skip_postcode_search == true
            sequence.delete("select-home-address")
          end

          if answers.ordnance_survey_error == true
            sequence.delete("select-home-address")
          end

          if answers.address_line_1.present? && answers.postcode.present?
            sequence.delete("address")
          end

          if answers.email_verified == true
            sequence.delete("email-verification")
          end

          if answers.provide_mobile_number == false
            sequence.delete("mobile-number")
            sequence.delete("mobile-verification")
          end

          if answers.mobile_verified == true
            sequence.delete("mobile-verification")
          end
        end
      end
    end
  end
end
