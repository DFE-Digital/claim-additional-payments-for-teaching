module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class MaybeEligibleForm < Form
      attribute :continue_claim, :boolean

      validates :continue_claim,
        inclusion: {
          in: [true, false],
          message: "Choose yes if you want to continue with your claim"
        }

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

      def save
        return false if invalid?

        journey_session.answers.update!(
          continue_claim:
        )

        true
      end
    end
  end
end
