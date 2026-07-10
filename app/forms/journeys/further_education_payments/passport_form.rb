module Journeys
  module FurtherEducationPayments
    class PassportForm < Form
      attribute :valid_passport, :boolean
      attribute :passport_number, :string

      validates :valid_passport,
        inclusion: {
          in: [true, false],
          message: i18n_error_message(:inclusion)
        }

      validates :passport_number,
        length: {
          minimum: 8,
          maximum: 9,
          message: i18n_error_message(:length)
        },
        if: proc { |form| form.valid_passport }

      def save
        return false if invalid?

        journey_session.answers.update!(
          valid_passport:,
          passport_number:
        )
      end
    end
  end
end
