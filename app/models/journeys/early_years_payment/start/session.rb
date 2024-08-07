module Journeys
  module EarlyYearsPayment
    module Start
      class Session < Journeys::Session
        attribute :answers, SessionAnswersType.new
      end
    end
  end
end
