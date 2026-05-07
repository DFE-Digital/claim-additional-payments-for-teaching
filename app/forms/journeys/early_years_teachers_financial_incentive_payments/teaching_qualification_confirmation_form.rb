module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class TeachingQualificationConfirmationForm < Form
      attribute :teaching_qualification_confirmation, :boolean

      validates :teaching_qualification_confirmation,
        inclusion: {
          in: ->(form) { form.radio_options.map(&:id) },
          message: i18n_error_message(:inclusion),
          allow_blank: false
        }

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(teaching_qualification_confirmation:)
        journey_session.save!
      end

      def radio_options
        [
          Option.new(
            id: true,
            name: t("options.true")
          ),
          Option.new(
            id: false,
            name: t("options.false")
          )
        ]
      end
    end
  end
end
