module Journeys
  module GetATeacherRelocationPayment
    class StartDateForm < Form
      include ActiveRecord::AttributeAssignment

      attribute :start_date, :date

      validates :start_date,
        presence: {
          message: i18n_error_message(:presence)
        }

      validates :start_date,
        comparison: {
          less_than: ->(_) { Date.tomorrow },
          message: i18n_error_message(:date_not_in_future)
        }, if: :start_date

      def initialize(journey_session:, journey:, params:, session: {})
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

        if start_date_changed?
          journey_session.answers.assign_attributes(date_of_entry: nil)
        end

        journey_session.answers.assign_attributes(start_date: start_date)

        journey_session.save!
      end

      private

      def start_date_changed?
        journey_session.answers.start_date != start_date
      end
    end
  end
end
