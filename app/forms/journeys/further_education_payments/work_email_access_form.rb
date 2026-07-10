module Journeys
  module FurtherEducationPayments
    class WorkEmailAccessForm < Form
      attribute :work_email_access, :boolean

      validates :work_email_access,
        inclusion: {
          in: ->(form) { form.radio_options.map(&:id) },
          message: ->(object, data) { i18n_error_message(:inclusion, school_name: object.school.name).call(object, data) }
        }

      def radio_options
        [
          Option.new(
            id: true,
            name: "Yes"
          ),
          Option.new(
            id: false,
            name: "No"
          )
        ]
      end

      def save
        return if invalid?

        journey_session.answers.update!(work_email_access:)
      end

      def school
        journey_session.answers.school
      end
    end
  end
end
