module Journeys
  module AdditionalPaymentsForTeaching
    class Session < Journeys::Session
      def journey_module
        Journeys::AdditionalPaymentsForTeaching
      end
    end
  end
end
