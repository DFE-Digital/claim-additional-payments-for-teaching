module Journeys
  module EarlyYearsPayment
    module Provider
      module Start
        class Session < Journeys::Session
          attribute :answers, SessionAnswersType.new

          def answers
            super.tap { it.session = self }
          end
        end
      end
    end
  end
end
