module Journeys
  module FurtherEducationPayments
    class Session < Journeys::Session
      def self.purgeable_age
        1.year.ago
      end
    end
  end
end
