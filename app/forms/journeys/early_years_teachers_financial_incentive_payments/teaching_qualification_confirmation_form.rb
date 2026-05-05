module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class TeachingQualificationConfirmationForm < Form
      attribute :teaching_qualification_confirmation, :boolean

      validates(
        :teaching_qualification_confirmation,
        inclusion: {in: [true, false], message: i18n_error_message(:blank)}
      )

      def save
        return false unless valid?

        journey_session.answers.update!(
          teaching_qualification_confirmation: teaching_qualification_confirmation
        )

        true
      end

      def completed?
        !answers.teaching_qualification_confirmation.nil?
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
