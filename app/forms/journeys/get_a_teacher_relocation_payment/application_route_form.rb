module Journeys
  module GetATeacherRelocationPayment
    class ApplicationRouteForm < Form
      attribute :application_route, :string
      validates :application_route,
        inclusion: {
          in: :available_options,
          message: i18n_error_message(:inclusion)
        }

      def available_options
        %w[teacher salaried_trainee other]
      end

      def save
        return false unless valid?

        journey_session.answers.update!(
          application_route: application_route
        )
      end

      private

      def application_route_changed?
        journey_session.answers.application_route != application_route
      end
    end
  end
end
