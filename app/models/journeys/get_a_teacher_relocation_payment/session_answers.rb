module Journeys
  module GetATeacherRelocationPayment
    class SessionAnswers < Journeys::SessionAnswers
      attribute :application_route, :string
      attribute :state_funded_secondary_school, :boolean
      attribute :one_year, :boolean

      def trainee?
        application_route == "salaried_trainee"
      end
    end
  end
end
