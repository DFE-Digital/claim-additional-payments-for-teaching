module Journeys
  module FurtherEducationPayments
    class TeachingHoursPerWeekForm < Form
      attribute :teaching_hours_per_week, :string

      validates :teaching_hours_per_week,
        inclusion: {in: ->(form) { form.radio_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def radio_options
        @radio_options ||= [
          OpenStruct.new(
            id: "more-than-12",
            name: "More than 12 hours per week"
          ),
          OpenStruct.new(
            id: "between-2.5-and-12",
            name: "Between 2.5 and 12 hours per week"
          ),
          OpenStruct.new(
            id: "less-than-2.5",
            name: "Less than 2.5 hours per week"
          )
        ]
      end

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(teaching_hours_per_week:)
        journey_session.save!
      end
    end
  end
end
