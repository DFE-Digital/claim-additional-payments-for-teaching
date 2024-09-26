module Journeys
  module EarlyYearsPayment
    module Practitioner
      class Session < Journeys::Session
        attribute :answers, SessionAnswersType.new
      end
    end
  end
end
