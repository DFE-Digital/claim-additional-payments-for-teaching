module Journeys
  module GetATeacherRelocationPayment
    class ApplicationRouteForm < Form
      attribute :application_route, :string

      def application_routes
        %i[teacher salaried_trainee other]
      end
    end
  end
end
