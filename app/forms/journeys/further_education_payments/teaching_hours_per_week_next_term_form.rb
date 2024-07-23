module Journeys
  module FurtherEducationPayments
    class TeachingHoursPerWeekNextTermForm < Form
      attribute :teaching_hours_per_week_next_term, :string

      validates :teaching_hours_per_week_next_term,
        inclusion: {in: ->(form) { form.radio_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def radio_options
        @radio_options ||= [
          OpenStruct.new(
            id: "at_least_2_5",
            name: t("options.at_least_2_5", school_name: school.name)
          ),
          OpenStruct.new(
            id: "less_than_2_5",
            name: t("options.less_than_2_5", school_name: school.name)
          )
        ]
      end

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(teaching_hours_per_week_next_term:)
        journey_session.save!
      end

      private

      def school
        journey_session.answers.school
      end
    end
  end
end
