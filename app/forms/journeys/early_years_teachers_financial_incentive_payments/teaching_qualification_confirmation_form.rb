module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class TeachingQualificationConfirmationForm < Form
      def save
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
