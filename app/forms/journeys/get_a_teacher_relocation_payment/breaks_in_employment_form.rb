require "ostruct"

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
          OpenStruct.new(id: true, name: "Yes"),
          OpenStruct.new(id: false, name: "No")
        ]
      end

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(breaks_in_employment:)
        journey_session.save!
      end
    end
  end
end
