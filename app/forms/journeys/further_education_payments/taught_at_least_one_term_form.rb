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
          Option.new(
            id: true,
            name: t("options.true", school_name: school.name)
          ),
          Option.new(
            id: false,
            name: t("options.false", school_name: school.name)
          )
        ]
      end

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(taught_at_least_one_term:)
        journey_session.save!
      end

      def clear_answers_from_session
        journey_session.answers.assign_attributes(taught_at_least_one_term: nil)
        journey_session.save!
      end

      def school
        journey_session.answers.school
      end
    end
  end
end
