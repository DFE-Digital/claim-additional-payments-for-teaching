module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class ContinueClaimForm < Form
      attribute :continue_claim, :boolean

      validates :continue_claim,
        inclusion: {
          in: [true, false],
          message: i18n_error_message(:blank)
        }

      def save
        return if invalid?

        journey_session.answers.update!(continue_claim:)

        true
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
