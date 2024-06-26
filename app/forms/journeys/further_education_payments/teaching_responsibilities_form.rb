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
          OpenStruct.new(id: true, name: "Yes"),
          OpenStruct.new(id: false, name: "No")
        ]
      end

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(teaching_responsibilities:)
        journey_session.save!
      end
    end
  end
end
