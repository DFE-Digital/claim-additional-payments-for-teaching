module Journeys
  module FurtherEducationPayments
    class TaughtAtLeastOneTermForm < Form
      attribute :taught_at_least_one_term, :boolean

      validates :taught_at_least_one_term,
        inclusion: {
          in: [true, false],
          message: ->(object, data) { i18n_error_message(:inclusion, school_name: object.school.name).call(object, data) }
        }

      def radio_options
        [
          OpenStruct.new(
            id: true,
            name: "Yes, I have taught at #{school.name} for at least one academic term"
          ),
          OpenStruct.new(
            id: false,
            name: "No, I have not taught at #{school.name} for at least one academic term"
          )
        ]
      end

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(taught_at_least_one_term:)
        journey_session.save!
      end

      def school
        journey_session.answers.school
      end
    end
  end
end
