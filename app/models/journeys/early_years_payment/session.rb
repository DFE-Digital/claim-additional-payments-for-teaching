module Journeys
  module EarlyYearsPayment
    class Session < Journeys::Session
      attribute :answers, SessionAnswersType.new
    end
  end
end
