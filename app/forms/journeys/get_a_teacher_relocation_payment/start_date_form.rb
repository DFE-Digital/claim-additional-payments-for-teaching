module Journeys
  module GetATeacherRelocationPayment
    class StartDateForm < Form
      include ActiveRecord::AttributeAssignment

      validates :start_date,
        presence: {
          message: i18n_error_message(:presence)
        }

      attribute :start_date, :date

      def initialize(journey_session:, journey:, params:)
        super

        # Handle setting date from multi part params see
        # ActiveRecord::AttributeAssignment
        _assign_attributes(permitted_params)
      rescue ActiveRecord::MultiparameterAssignmentErrors
        # Invalid date was entered
        self.start_date = nil
      end

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(start_date: start_date)

        journey_session.save!
      end
    end
  end
end
