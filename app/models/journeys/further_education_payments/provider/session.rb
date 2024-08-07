module Journeys
  module FurtherEducationPayments
    module Provider
      class Session < Journeys::Session
        attribute :answers, SessionAnswersType.new
      end
    end
  end
end
