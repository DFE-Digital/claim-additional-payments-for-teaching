module Journeys
  module GetATeacherRelocationPayment
    class SessionAnswers < Journeys::SessionAnswers
      attribute :application_route, :string
    end
  end
end
