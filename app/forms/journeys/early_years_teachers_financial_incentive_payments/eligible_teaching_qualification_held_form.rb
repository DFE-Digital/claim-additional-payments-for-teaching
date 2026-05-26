module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class EligibleTeachingQualificationHeldForm < Form
      attribute :eligible_teaching_qualification_held_clicked, :boolean

      def save
        journey_session.answers.update!(eligible_teaching_qualification_held_clicked: true)

        true
      end

      def completed?
        journey_session.answers.eligible_teaching_qualification_held_clicked
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
