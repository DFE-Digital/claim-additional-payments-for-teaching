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

        journey_session.answers.assign_attributes(
          application_route: application_route
        )

        journey_session.save!
      end
    end
  end
end
