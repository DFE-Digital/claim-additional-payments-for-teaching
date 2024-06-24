module Journeys
  module GetATeacherRelocationPayment
    class SlugSequence
      ELIGIBILITY_SLUGS = [
        "application-route",
        "state-funded-secondary-school",
        "trainee-details",
        "contract-details",
        "start-date",
        "subject",
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
        SLUGS.dup.tap do |sequence|
          if answers.trainee?
            sequence.delete("state-funded-secondary-school")
            sequence.delete("contract-details")
          else
            sequence.delete("trainee-details")
          end
        end
      end
    end
  end
end
