module Journeys
  module FurtherEducationPayments
    class Session < Journeys::Session
      attribute :answers, SessionAnswersType.new
    end
  end
end
