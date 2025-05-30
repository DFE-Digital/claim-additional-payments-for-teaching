module Journeys
  module FurtherEducationPayments
    class HalfTeachingHoursForm < Form
      attribute :half_teaching_hours, :boolean

      validates :half_teaching_hours,
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
        return false unless valid?

        journey_session.answers.assign_attributes(half_teaching_hours:)
        journey_session.save!
      end
    end
  end
end
