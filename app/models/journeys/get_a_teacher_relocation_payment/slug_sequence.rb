module Journeys
  module GetATeacherRelocationPayment
    class SlugSequence
      ELIGIBILITY_SLUGS = [
        "application-route",
        "check-your-answers-part-one"
      ]

      RESULTS_SLUGS = [
        "check-your-answers",
        "ineligible"
      ].freeze

      SLUGS = ELIGIBILITY_SLUGS + RESULTS_SLUGS

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
        SLUGS
      end
    end
  end
end
