module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class TeacherDetailsForm < Form
      attribute :correct_details, :boolean

      validates :correct_details,
        inclusion: {
          in: [true, false],
          message: "Select yes if your details are correct"
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
        return false if invalid?

        journey_session.answers.update!(
          correct_details:
        )
      end
    end
  end
end
