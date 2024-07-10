module Journeys
  module GetATeacherRelocationPayment
    class Session < Journeys::Session
      attribute :answers, SessionAnswersType.new
    end
  end
end
