module Journeys
  module GetATeacherRelocationPayment
    class SlugSequence
      # FIXME RL due to how the page sequence works we need a minimum of 2
      # slugs otherwise there's no next slug to go to. Once we have added
      # another page remove the duplicate "check-your-answers" slug.
      RESULTS_SLUGS = [
        "check-your-answers",
        "check-your-answers"
      ].freeze

      SLUGS = RESULTS_SLUGS

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
