module Journeys
  module GetATeacherRelocationPayment
    class PassportNumberForm < Form
      attribute :passport_number, :string

      validates :passport_number, presence: {
        message: i18n_error_message(:presence)
      }

      validates :passport_number, format: {
        with: /\A[a-zA-Z0-9]{1,20}\z/,
        message: i18n_error_message(:invalid)
      }, if: :passport_number

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          passport_number: passport_number
        )

        journey_session.save!
      end
    end
  end
end
