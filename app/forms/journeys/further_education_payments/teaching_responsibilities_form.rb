module Journeys
  module FurtherEducationPayments
    class TeachingResponsibilitiesForm < Form
      attribute :teaching_responsibilities, :boolean

      validates :teaching_responsibilities,
        inclusion: {
          in: [true, false],
          message: i18n_error_message(:inclusion)
        }

      def radio_options
        [
          Option.new(id: true, name: "Yes"),
          Option.new(id: false, name: "No")
        ]
      end

      def save
        return false if invalid?

        journey_session.answers.update!(teaching_responsibilities:)
      end

      def clear_answers_from_session
        journey_session.answers.update!(teaching_responsibilities: nil)
      end
    end
  end
end
