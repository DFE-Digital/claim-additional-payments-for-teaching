module Journeys
  module GetATeacherRelocationPayment
    class EntryDateForm < Form
      include ActiveRecord::AttributeAssignment

      attribute :date_of_entry, :date

      validates :date_of_entry, presence: {
        message: i18n_error_message(:presence)
      }

      validates :date_of_entry,
        comparison: {
          less_than: ->(_) { Date.tomorrow },
          message: i18n_error_message(:date_not_in_future)
        }, if: :date_of_entry

      def initialize(journey_session:, journey:, params:, session: {})
        super

        # Handle setting date from multi part params see
        # ActiveRecord::AttributeAssignment
        _assign_attributes(permitted_params)
      rescue ActiveRecord::MultiparameterAssignmentErrors
        # Invalid date was entered
        self.date_of_entry = nil
      end

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(date_of_entry: date_of_entry)

        journey_session.save!
      end
    end
  end
end
