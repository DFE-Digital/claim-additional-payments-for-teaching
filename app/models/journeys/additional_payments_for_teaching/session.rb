module Journeys
  module AdditionalPaymentsForTeaching
    class Session < Journeys::Session
      attribute :answers, SessionAnswersType.new
    end
  end
end
