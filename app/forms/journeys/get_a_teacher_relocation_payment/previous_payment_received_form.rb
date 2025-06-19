module Journeys
  module GetATeacherRelocationPayment
    class PreviousPaymentReceivedForm < Form
      attribute :previous_payment_received, :boolean

      validates :previous_payment_received,
        inclusion: {
          in: ->(form) { form.radio_options.map(&:id) },
          message: i18n_error_message(:inclusion)
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
        return false unless valid?

        journey_session.answers.assign_attributes(
          previous_payment_received: previous_payment_received
        )

        journey_session.save!
      end
    end
  end
end
