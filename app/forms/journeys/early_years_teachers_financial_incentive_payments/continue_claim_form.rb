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

        if claim_cancelled?
          session.clear
        end

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

      private

      def claim_cancelled?
        continue_claim == false
      end
    end
  end
end
