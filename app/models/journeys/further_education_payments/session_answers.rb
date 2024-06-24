module Journeys
  module FurtherEducationPayments
    class SessionAnswers < Journeys::SessionAnswers
      attribute :teaching_responsibilities, :boolean
    end
  end
end
