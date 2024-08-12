module Journeys
  module EarlyYearsPayment
    module Provider
      module Start
        class Session < Journeys::Session
          attribute :answers, SessionAnswersType.new
        end
      end
    end
  end
end
