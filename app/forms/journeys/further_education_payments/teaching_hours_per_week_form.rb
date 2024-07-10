module Journeys
  module FurtherEducationPayments
    class TeachingHoursPerWeekForm < Form
      attribute :teaching_hours_per_week, :string

      validates :teaching_hours_per_week,
        inclusion: {in: ->(form) { form.radio_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def radio_options
        @radio_options ||= [
          OpenStruct.new(
            id: "more_than_12",
            name: t("options.more_than_12")
          ),
          OpenStruct.new(
            id: "between_2_5_and_12",
            name: t("options.between_2_5_and_12")
          ),
          OpenStruct.new(
            id: "less_than_2_5",
            name: t("options.less_than_2_5")
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
