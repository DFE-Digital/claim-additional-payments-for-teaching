module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class HalfContractedHoursForm < Form
      attribute :half_contracted_hours, :boolean

      validates :half_contracted_hours,
        inclusion: {
          in: [true, false],
          message: "Choose yes if spend at least half of your contracted hours teaching chemistry, computing, mathematics or physics"
        }

      def save
        return false if invalid?

        journey_session
          .answers
          .update!(half_contracted_hours:)
      end

      def radio_options
        [
          Form::Option.new(
            id: true,
            name: "Yes"
          ),
          Form::Option.new(
            id: false,
            name: "No"
          )
        ]
      end
    end
  end
end
