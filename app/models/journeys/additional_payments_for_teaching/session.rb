module Journeys
  module AdditionalPaymentsForTeaching
    class Session < Journeys::Session
      attribute :answers, SessionAnswersType.new

      def journey_module
        Journeys::AdditionalPaymentsForTeaching
      end
    end
  end
end
