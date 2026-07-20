module Journeys
  module GetATeacherRelocationPayment
    class BreaksInEmploymentForm < Form
      attribute :breaks_in_employment, :boolean

      validates :breaks_in_employment,
        inclusion: {
          in: [true, false],
          message: i18n_error_message(:inclusion)
        }

      def radio_options
        @radio_options ||= [
          Option.new(id: true, name: "Yes"),
          Option.new(id: false, name: "No")
        ]
      end

      def save
        return false if invalid?

        journey_session.answers.update!(breaks_in_employment:)
      end
    end
  end
end
